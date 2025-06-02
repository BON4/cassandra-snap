import subprocess
import yaml
import pytest

NUM_OPS = 100
THREADS = 2
CL = "ONE"

def run_command(cmd):
    result = subprocess.run(cmd, shell=False, text=True, capture_output=True)
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr)
        raise subprocess.CalledProcessError(result.returncode, cmd)
    return result.stdout

def is_snap_installed():
    try:
        subprocess.run(["snap", "--version"], check=True)
        return True
    except Exception:
        return False

def cassandra_stress_available():
    try:
        subprocess.run(["sudo", "snap", "run", "cassandra.stress", "help"], check=True)
        return True
    except Exception:
        return False

def test_install():
    with open("snap/snapcraft.yaml") as file:
        snapcraft = yaml.safe_load(file)
        snap_file = f"./{snapcraft['name']}_{snapcraft['version']}_amd64.snap"
        subprocess.run(
            ["sudo", "snap", "install", snap_file, "--devmode"],
            check=True,
        )
        
@pytest.mark.run(after="test_install")
def check_nodetool_status():
    if not is_snap_installed():
        pytest.fail("[FAILED] snap command not found")
    
    print("Running nodetool status...")

    try:
        output = subprocess.check_output(
            ['sudo', 'snap', 'run', 'cassandra.nodetool', 'status'],
            text=True,
            stderr=subprocess.STDOUT
        )
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Failed to run nodetool status: {e.output}") from e

    print(output)

    if "UN" in output:
        print("Nodetool status is healthy: Node is Up and Normal.")
    else:
        raise RuntimeError("Nodetool status check failed! Node is not Up and Normal.")
        

@pytest.mark.run(after="check_nodetool_status")
def test_write_stress():
    if not is_snap_installed():
        pytest.fail("[FAILED] snap command not found")

    if not cassandra_stress_available():
        pytest.fail("[FAILED] cassandra-stress is not installed or not available via snap")

    print("▶ Starting WRITE test...")
    try:
        run_command([
            "snap", "run", "cassandra.stress", "write",
            f"n={NUM_OPS}",
            f"cl={CL}",
            "-rate",
            f"threads={THREADS}"
        ])
    except subprocess.CalledProcessError:
        pytest.fail("[FAILED] WRITE test failed")
    print("[SUCCESS] WRITE test completed")

@pytest.mark.run(after="check_nodetool_status")
def test_read_stress():
    if not is_snap_installed():
        pytest.fail("[FAILED] snap command not found")

    if not cassandra_stress_available():
        pytest.fail("[FAILED] cassandra-stress is not installed or not available via snap")

    
    print("▶ Starting READ test...")
    try:
        run_command([
            "snap", "run", "cassandra.stress", "read",
            f"n={NUM_OPS}",
            f"cl={CL}",
            "-rate",
            f"threads={THREADS}"
        ])
    except subprocess.CalledProcessError:
        pytest.fail("[FAILED] READ test failed")
    print("[SUCCESS] READ test completed")
