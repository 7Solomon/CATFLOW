from pathlib import Path

def create_minimal_required_files(base_path: Path):
    """
    Creates minimal versions of all required CATFLOW input files
    USED for initializing a new project
    """
    base_path.mkdir(parents=True, exist_ok=True)
    
    # 1. Wind direction factors
    winddir = base_path / "in/climate/winddir.def"
    winddir.parent.mkdir(parents=True, exist_ok=True)
    with open(winddir, 'w') as f:
        f.write("% Wind direction factors\n")
        f.write("5  % Number of sectors\n")
        f.write("0.0 72.0 1.0\n")
        f.write("72.0 144.0 1.0\n")
        f.write("144.0 216.0 1.0\n")
        f.write("216.0 288.0 1.0\n")
        f.write("288.0 360.0 1.0\n")
    
    # 2. Control volumes
    cv = base_path / "in/control/cont_vol.cv"
    cv.parent.mkdir(parents=True, exist_ok=True)
    with open(cv, 'w') as f:
        f.write("1  % Number of control volumes\n")
        f.write("1 1 1 1  % iv_top iv_bot il_left il_right\n")
    
    print("✓ Created minimal required files")