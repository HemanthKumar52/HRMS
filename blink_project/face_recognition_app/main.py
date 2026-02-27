"""CLI entry point for the Face Recognition & Verification System."""

import argparse
import sys

from database import init_db, list_names, delete_face, get_name_counts, get_angle_counts, total_embeddings


def main():
    parser = argparse.ArgumentParser(
        description="Face Recognition & Verification System (Multi-Angle + Liveness)"
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Guided register (multi-angle)
    reg_guided = subparsers.add_parser("register", help="Guided multi-angle registration")
    reg_guided.add_argument("--name", required=True, help="Name for the face")
    reg_guided.add_argument("--images", nargs="*",
                            help="Image files (auto-detects pose). Uses guided webcam if omitted.")
    reg_guided.add_argument("--simple", action="store_true",
                            help="Use simple capture (no pose guidance)")

    # Add samples
    add_p = subparsers.add_parser("add-samples", help="Add more samples to existing face")
    add_p.add_argument("--name", required=True)
    add_p.add_argument("--images", nargs="+", required=True)

    # Verify
    ver_p = subparsers.add_parser("verify", help="Real-time face verification")
    ver_p.add_argument("--threshold", type=float, default=None)

    # Liveness check
    subparsers.add_parser("liveness", help="Run standalone liveness check")

    # List
    subparsers.add_parser("list", help="List all registered faces with angle breakdown")

    # Delete
    del_p = subparsers.add_parser("delete", help="Delete a registered face")
    del_p.add_argument("--name", required=True)

    # Web UI
    subparsers.add_parser("web", help="Launch Streamlit web UI")

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(1)

    init_db()

    if args.command == "register":
        from face_embedder import FaceEmbedder
        from register import register_face_guided_cli, register_face_cli, register_face_from_images

        embedder = FaceEmbedder()
        if args.images:
            register_face_from_images(args.name, args.images, embedder=embedder)
        elif args.simple:
            register_face_cli(args.name, embedder=embedder)
        else:
            register_face_guided_cli(args.name, embedder=embedder)

    elif args.command == "add-samples":
        from face_embedder import FaceEmbedder
        from register import add_samples_to_existing

        embedder = FaceEmbedder()
        add_samples_to_existing(args.name, args.images, embedder=embedder)

    elif args.command == "verify":
        from face_embedder import FaceEmbedder
        from verify import verify_realtime_cli

        embedder = FaceEmbedder()
        verify_realtime_cli(embedder=embedder, threshold=args.threshold)

    elif args.command == "liveness":
        from face_embedder import FaceEmbedder
        from liveness import run_liveness_check_cli

        embedder = FaceEmbedder()
        result = run_liveness_check_cli(embedder)
        if result.alive:
            print(f"ALIVE - passed: {result.steps_passed}, blinks: {result.blink_count}")
        else:
            print(f"FAILED - reason: {result.reason}, "
                  f"passed: {result.steps_passed}, failed: {result.steps_failed}")

    elif args.command == "list":
        counts = get_name_counts()
        total = total_embeddings()
        if counts:
            print(f"Registered faces ({len(counts)} people, {total} total embeddings):\n")
            for name, count in counts.items():
                angle_info = get_angle_counts(name)
                breakdown = ", ".join(f"{a}={c}" for a, c in angle_info.items())
                print(f"  {name}: {count} embeddings ({breakdown})")
        else:
            print("No faces registered.")

    elif args.command == "delete":
        if delete_face(args.name):
            print(f"Deleted '{args.name}'.")
        else:
            print(f"Face '{args.name}' not found.")

    elif args.command == "web":
        import os
        import subprocess
        subprocess.run(
            [sys.executable, "-m", "streamlit", "run", "app.py",
             "--server.headless", "true", "--browser.gatherUsageStats", "false"],
            cwd=os.path.dirname(os.path.abspath(__file__)),
        )


if __name__ == "__main__":
    main()
