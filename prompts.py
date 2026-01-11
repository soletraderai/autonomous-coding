"""
Prompt Loading Utilities
========================

Functions for loading prompt templates with project-specific support.

Fallback chain:
1. Project-specific: generations/{project}/prompts/{name}.md
2. Base template: .claude/templates/{name}.template.md
"""

from __future__ import annotations

import shutil
from pathlib import Path
from typing import Optional


# Base templates location (generic templates)
TEMPLATES_DIR = Path(__file__).parent / ".claude" / "templates"

# System root directory (where VERSION file lives)
SYSTEM_ROOT = Path(__file__).parent


def get_system_version() -> str:
    """
    Get the current system version from the VERSION file.

    Returns:
        Version string (e.g., "1.0.0"), or "unknown" if VERSION file not found
    """
    version_file = SYSTEM_ROOT / "VERSION"
    if version_file.exists():
        try:
            return version_file.read_text(encoding="utf-8").strip()
        except (OSError, PermissionError):
            pass
    return "unknown"


def get_project_version(project_dir: Path) -> str | None:
    """
    Get the version a project was created with.

    Args:
        project_dir: The project directory

    Returns:
        Version string if .version file exists, None otherwise
    """
    version_file = project_dir / ".version"
    if version_file.exists():
        try:
            return version_file.read_text(encoding="utf-8").strip()
        except (OSError, PermissionError):
            pass
    return None


def stamp_project_version(project_dir: Path) -> None:
    """
    Stamp a project with the current system version.

    Creates a .version file in the project directory with the current
    system version. Only stamps if no .version file exists.

    Args:
        project_dir: The project directory
    """
    version_file = project_dir / ".version"
    if version_file.exists():
        return  # Already stamped

    version = get_system_version()
    try:
        version_file.write_text(version + "\n", encoding="utf-8")
        print(f"  Stamped project with version: {version}")
    except (OSError, PermissionError) as e:
        print(f"  Warning: Could not stamp version: {e}")


def get_project_prompts_dir(project_dir: Path) -> Path:
    """Get the prompts directory for a specific project."""
    return project_dir / "prompts"


def load_prompt(name: str, project_dir: Path | None = None) -> str:
    """
    Load a prompt template with fallback chain.

    Fallback order:
    1. Project-specific: {project_dir}/prompts/{name}.md
    2. Base template: .claude/templates/{name}.template.md

    Args:
        name: The prompt name (without extension), e.g., "initializer_prompt"
        project_dir: Optional project directory for project-specific prompts

    Returns:
        The prompt content as a string

    Raises:
        FileNotFoundError: If prompt not found in any location
    """
    # 1. Try project-specific first
    if project_dir:
        project_prompts = get_project_prompts_dir(project_dir)
        project_path = project_prompts / f"{name}.md"
        if project_path.exists():
            try:
                return project_path.read_text(encoding="utf-8")
            except (OSError, PermissionError) as e:
                print(f"Warning: Could not read {project_path}: {e}")

    # 2. Try base template
    template_path = TEMPLATES_DIR / f"{name}.template.md"
    if template_path.exists():
        try:
            return template_path.read_text(encoding="utf-8")
        except (OSError, PermissionError) as e:
            print(f"Warning: Could not read {template_path}: {e}")

    raise FileNotFoundError(
        f"Prompt '{name}' not found in:\n"
        f"  - Project: {project_dir / 'prompts' if project_dir else 'N/A'}\n"
        f"  - Templates: {TEMPLATES_DIR}"
    )


def get_initializer_prompt(project_dir: Path | None = None) -> str:
    """Load the initializer prompt (project-specific if available)."""
    return load_prompt("initializer_prompt", project_dir)


def get_coding_prompt(project_dir: Path | None = None) -> str:
    """Load the coding agent prompt (project-specific if available)."""
    return load_prompt("coding_prompt", project_dir)


def get_app_spec(project_dir: Path) -> str:
    """
    Load the app spec from the project.

    Checks in order:
    1. Project prompts directory: {project_dir}/prompts/app_spec.txt
    2. Project root (legacy): {project_dir}/app_spec.txt

    Args:
        project_dir: The project directory

    Returns:
        The app spec content

    Raises:
        FileNotFoundError: If no app_spec.txt found
    """
    # Try project prompts directory first
    project_prompts = get_project_prompts_dir(project_dir)
    spec_path = project_prompts / "app_spec.txt"
    if spec_path.exists():
        try:
            return spec_path.read_text(encoding="utf-8")
        except (OSError, PermissionError) as e:
            raise FileNotFoundError(f"Could not read {spec_path}: {e}") from e

    # Fallback to legacy location in project root
    legacy_spec = project_dir / "app_spec.txt"
    if legacy_spec.exists():
        try:
            return legacy_spec.read_text(encoding="utf-8")
        except (OSError, PermissionError) as e:
            raise FileNotFoundError(f"Could not read {legacy_spec}: {e}") from e

    raise FileNotFoundError(f"No app_spec.txt found for project: {project_dir}")


def get_phase_spec(project_dir: Path, phase: int) -> str:
    """
    Load the specification for a specific phase.

    Phase 1 uses app_spec.txt.
    Phase N (N > 1) uses prompts/phaseN_spec.txt.

    Args:
        project_dir: The project directory
        phase: Phase number (1, 2, 3, etc.)

    Returns:
        The specification content as a string

    Raises:
        FileNotFoundError: If spec file not found for the phase
    """
    if phase == 1:
        return get_app_spec(project_dir)

    # For phase 2+, look for phaseN_spec.txt
    project_prompts = get_project_prompts_dir(project_dir)
    spec_filename = f"phase{phase}_spec.txt"
    spec_path = project_prompts / spec_filename

    if spec_path.exists():
        try:
            return spec_path.read_text(encoding="utf-8")
        except (OSError, PermissionError) as e:
            raise FileNotFoundError(f"Could not read {spec_path}: {e}") from e

    # Also check project root as fallback
    root_spec = project_dir / spec_filename
    if root_spec.exists():
        try:
            return root_spec.read_text(encoding="utf-8")
        except (OSError, PermissionError) as e:
            raise FileNotFoundError(f"Could not read {root_spec}: {e}") from e

    raise FileNotFoundError(
        f"No specification file found for Phase {phase}.\n"
        f"Expected: {spec_path}\n"
        f"Create this file with your Phase {phase} requirements."
    )


def get_phase_initializer_prompt(project_dir: Path, phase: int) -> str:
    """
    Load the initializer prompt for a specific phase.

    For phase 1, uses the standard initializer_prompt.
    For phase 2+, uses phase_initializer_prompt with phase context.

    Args:
        project_dir: The project directory
        phase: Phase number

    Returns:
        The prompt content with phase information substituted
    """
    if phase == 1:
        return get_initializer_prompt(project_dir)

    # Load phase initializer template
    template = load_prompt("phase_initializer_prompt", project_dir)

    # Load the phase spec
    phase_spec = get_phase_spec(project_dir, phase)

    # Substitute placeholders
    prompt = template.replace("{{PHASE_NUMBER}}", str(phase))
    prompt = prompt.replace("{{PHASE_SPEC}}", phase_spec)

    return prompt


def scaffold_project_prompts(project_dir: Path) -> Path:
    """
    Create the project prompts directory and copy base templates.

    This sets up a new project with template files that can be customized.
    Also stamps the project with the current system version.

    Args:
        project_dir: The project directory (e.g., generations/my-app)

    Returns:
        The path to the project prompts directory
    """
    project_prompts = get_project_prompts_dir(project_dir)
    project_prompts.mkdir(parents=True, exist_ok=True)

    # Stamp project with current system version
    stamp_project_version(project_dir)

    # Define template mappings: (source_template, destination_name)
    templates = [
        ("app_spec.template.txt", "app_spec.txt"),
        ("coding_prompt.template.md", "coding_prompt.md"),
        ("initializer_prompt.template.md", "initializer_prompt.md"),
    ]

    copied_files = []
    for template_name, dest_name in templates:
        template_path = TEMPLATES_DIR / template_name
        dest_path = project_prompts / dest_name

        # Only copy if template exists and destination doesn't
        if template_path.exists() and not dest_path.exists():
            try:
                shutil.copy(template_path, dest_path)
                copied_files.append(dest_name)
            except (OSError, PermissionError) as e:
                print(f"  Warning: Could not copy {dest_name}: {e}")

    if copied_files:
        print(f"  Created prompt files: {', '.join(copied_files)}")

    return project_prompts


def has_project_prompts(project_dir: Path) -> bool:
    """
    Check if a project has valid prompts set up.

    A project has valid prompts if:
    1. The prompts directory exists, AND
    2. app_spec.txt exists within it, AND
    3. app_spec.txt contains the <project_specification> tag

    Args:
        project_dir: The project directory to check

    Returns:
        True if valid project prompts exist, False otherwise
    """
    project_prompts = get_project_prompts_dir(project_dir)
    app_spec = project_prompts / "app_spec.txt"

    if not app_spec.exists():
        # Also check legacy location in project root
        legacy_spec = project_dir / "app_spec.txt"
        if legacy_spec.exists():
            try:
                content = legacy_spec.read_text(encoding="utf-8")
                return "<project_specification>" in content
            except (OSError, PermissionError):
                return False
        return False

    # Check for valid spec content
    try:
        content = app_spec.read_text(encoding="utf-8")
        return "<project_specification>" in content
    except (OSError, PermissionError):
        return False


def copy_spec_to_project(project_dir: Path) -> None:
    """
    Copy the app spec file into the project root directory for the agent to read.

    This maintains backwards compatibility - the agent expects app_spec.txt
    in the project root directory.

    The spec is sourced from: {project_dir}/prompts/app_spec.txt

    Args:
        project_dir: The project directory
    """
    spec_dest = project_dir / "app_spec.txt"

    # Don't overwrite if already exists
    if spec_dest.exists():
        return

    # Copy from project prompts directory
    project_prompts = get_project_prompts_dir(project_dir)
    project_spec = project_prompts / "app_spec.txt"
    if project_spec.exists():
        try:
            shutil.copy(project_spec, spec_dest)
            print("Copied app_spec.txt to project directory")
            return
        except (OSError, PermissionError) as e:
            print(f"Warning: Could not copy app_spec.txt: {e}")
            return

    print("Warning: No app_spec.txt found to copy to project directory")
