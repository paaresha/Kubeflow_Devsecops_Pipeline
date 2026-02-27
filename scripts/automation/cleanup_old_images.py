#!/usr/bin/env python3
"""
=============================================================================
ECR Image Cleanup Script
=============================================================================
Deletes old/untagged images from ECR repositories to save storage costs.
Keeps the N most recent images and removes the rest.

Usage:
  python scripts/automation/cleanup_old_images.py
  python scripts/automation/cleanup_old_images.py --keep 15
  python scripts/automation/cleanup_old_images.py --dry-run
  python scripts/automation/cleanup_old_images.py --service order-service
=============================================================================
"""

import argparse
import json
import sys
from datetime import datetime, timezone

try:
    import boto3
except ImportError:
    print("ERROR: 'boto3' package required. Install with: pip install boto3")
    sys.exit(1)

PROJECT_NAME = "kubeflow-ops"
SERVICES = ["order-service", "user-service", "notification-service"]
AWS_REGION = "us-east-1"


def get_ecr_client():
    return boto3.client("ecr", region_name=AWS_REGION)


def list_images(ecr_client, repo_name: str) -> list[dict]:
    """List all images in a repository, sorted by push date (newest first)."""
    images = []
    paginator = ecr_client.get_paginator("describe_images")

    try:
        for page in paginator.paginate(repositoryName=repo_name):
            for img in page.get("imageDetails", []):
                images.append({
                    "digest": img["imageDigest"],
                    "tags": img.get("imageTags", []),
                    "pushed_at": img.get("imagePushedAt", datetime.min.replace(tzinfo=timezone.utc)),
                    "size_mb": round(img.get("imageSizeInBytes", 0) / (1024 * 1024), 2),
                })
    except ecr_client.exceptions.RepositoryNotFoundException:
        print(f"  ⚠️  Repository '{repo_name}' not found — skipping")
        return []

    # Sort by push date (newest first)
    images.sort(key=lambda x: x["pushed_at"], reverse=True)
    return images


def cleanup_repository(ecr_client, repo_name: str, keep: int, dry_run: bool) -> dict:
    """Remove old images from a repository, keeping N most recent."""
    images = list_images(ecr_client, repo_name)

    if not images:
        return {"repo": repo_name, "total": 0, "deleted": 0, "freed_mb": 0}

    # Separate tagged and untagged
    to_keep = images[:keep]
    to_delete = images[keep:]

    # Always delete untagged images regardless of 'keep' count
    untagged = [img for img in to_keep if not img["tags"]]
    if untagged:
        to_delete.extend(untagged)
        to_keep = [img for img in to_keep if img["tags"]]

    freed_mb = sum(img["size_mb"] for img in to_delete)

    print(f"\n  📦 {repo_name}")
    print(f"     Total images: {len(images)}")
    print(f"     Keeping: {len(to_keep)} (most recent)")
    print(f"     Deleting: {len(to_delete)} ({freed_mb:.1f} MB)")

    if to_delete and not dry_run:
        # ECR batch delete (max 100 at a time)
        batch_size = 100
        for i in range(0, len(to_delete), batch_size):
            batch = to_delete[i:i + batch_size]
            image_ids = [{"imageDigest": img["digest"]} for img in batch]

            try:
                response = ecr_client.batch_delete_image(
                    repositoryName=repo_name,
                    imageIds=image_ids,
                )
                failures = response.get("failures", [])
                if failures:
                    print(f"     ⚠️  {len(failures)} images failed to delete")
                    for f in failures:
                        print(f"        {f['imageId']['imageDigest'][:12]}: {f['failureReason']}")
            except Exception as e:
                print(f"     ❌ Error deleting batch: {e}")

        print(f"     ✅ Deleted {len(to_delete)} images")
    elif dry_run and to_delete:
        print(f"     🔍 DRY RUN — would delete:")
        for img in to_delete[:5]:
            tags = ", ".join(img["tags"]) if img["tags"] else "<untagged>"
            print(f"        {tags} ({img['size_mb']} MB, pushed {img['pushed_at']})")
        if len(to_delete) > 5:
            print(f"        ... and {len(to_delete) - 5} more")

    return {
        "repo": repo_name,
        "total": len(images),
        "deleted": len(to_delete),
        "freed_mb": freed_mb,
    }


def main():
    parser = argparse.ArgumentParser(description="Clean up old ECR images")
    parser.add_argument("--keep", type=int, default=10,
                        help="Number of most recent images to keep (default: 10)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be deleted without actually deleting")
    parser.add_argument("--service", type=str, default=None,
                        help="Only clean up a specific service (e.g., order-service)")
    args = parser.parse_args()

    services = [args.service] if args.service else SERVICES

    print("\n" + "=" * 60)
    print("  ECR Image Cleanup")
    print(f"  Keep: {args.keep} most recent | Dry Run: {args.dry_run}")
    print("=" * 60)

    ecr_client = get_ecr_client()
    total_freed = 0
    total_deleted = 0

    for service in services:
        repo_name = f"{PROJECT_NAME}-{service}"
        result = cleanup_repository(ecr_client, repo_name, args.keep, args.dry_run)
        total_freed += result["freed_mb"]
        total_deleted += result["deleted"]

    # ── Summary ──────────────────────────────────────────────────────────
    print("\n" + "-" * 60)
    prefix = "Would delete" if args.dry_run else "Deleted"
    print(f"  {prefix}: {total_deleted} images ({total_freed:.1f} MB)")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
