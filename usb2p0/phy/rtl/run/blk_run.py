#!/usr/bin/env python3
"""
QuestaSim SystemVerilog Compilation and Simulation Script
Compiles design and testbench, elaborates, and runs simulation
"""

import argparse
import subprocess
import sys
import os

def run_command(cmd, step_name, log_file=None):
    """Run a shell command and check for errors"""
    print(f"\n{'='*60}")
    print(f"Step: {step_name}")
    print(f"Command: {' '.join(cmd)}")
    if log_file:
        print(f"Log file: {log_file}")
    print('='*60)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    # Write to log file if specified
    if log_file:
        with open(log_file, 'w') as f:
            f.write(f"Command: {' '.join(cmd)}\n")
            f.write(f"{'='*60}\n\n")
            if result.stdout:
                f.write("STDOUT:\n")
                f.write(result.stdout)
                f.write("\n")
            if result.stderr:
                f.write("STDERR:\n")
                f.write(result.stderr)
                f.write("\n")
            f.write(f"\nReturn code: {result.returncode}\n")
    
    # Print stdout and stderr
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    
    if result.returncode != 0:
        print(f"\n❌ ERROR: {step_name} failed with return code {result.returncode}")
        if log_file:
            print(f"Check {log_file} for details")
        sys.exit(1)
    
    print(f"✓ {step_name} completed successfully")
    if log_file:
        print(f"✓ Log saved to {log_file}")
    return result

def main():
    parser = argparse.ArgumentParser(
        description='Compile, elaborate and simulate SystemVerilog files using QuestaSim'
    )
    parser.add_argument(
        'name',
        help='Base name for design file (will look for <name>.sv and <name>_tb.sv)'
    )
    parser.add_argument(
        '--dump',
        action='store_true',
        help='Enable VCD/waveform dump during simulation'
    )
    parser.add_argument(
        '--work',
        default='work',
        help='Work library name (default: work)'
    )
    parser.add_argument(
        '--top',
        help='Top-level module name for simulation (default: <name>_tb)'
    )
    
    args = parser.parse_args()
    
    # Construct filenames with relative paths
    design_file = os.path.join("..", f"{args.name}.sv")
    tb_file = os.path.join("..", "tb", f"{args.name}_tb.sv")
    top_module = args.top if args.top else f"{args.name}_tb"
    
    # Check if files exist
    if not os.path.exists(design_file):
        print(f"❌ ERROR: Design file '{design_file}' not found")
        sys.exit(1)
    
    if not os.path.exists(tb_file):
        print(f"❌ ERROR: Testbench file '{tb_file}' not found")
        sys.exit(1)
    
    print(f"\n{'='*60}")
    print(f"QuestaSim SystemVerilog Simulation Flow")
    print(f"{'='*60}")
    print(f"Design file:    {design_file}")
    print(f"Testbench file: {tb_file}")
    print(f"Top module:     {top_module}")
    print(f"Work library:   {args.work}")
    print(f"Dump enabled:   {args.dump}")
    
    # Step 1: Create work library if it doesn't exist
    if not os.path.exists(args.work):
        run_command(['vlib', args.work], "Creating work library", f"{args.name}_vlib.log")
    
    # Step 2: Compile design file
    compile_design_cmd = ['vlog', '-sv', '-work', args.work, design_file]
    run_command(compile_design_cmd, f"Compiling {design_file}", f"{args.name}_compile_design.log")
    
    # Step 3: Compile testbench file
    compile_tb_cmd = ['vlog', '-sv', '-work', args.work, tb_file]
    run_command(compile_tb_cmd, f"Compiling {tb_file}", f"{args.name}_compile_tb.log")
    
    # Step 4: Elaborate
    elab_cmd = ['vopt', '+acc', '-work', args.work, top_module, '-o', f"{top_module}_opt"]
    run_command(elab_cmd, f"Elaborating {top_module}", f"{args.name}_elaborate.log")
    
    # Step 5: Run simulation
    sim_cmd = ['vsim', '-c', '-work', args.work, f"{top_module}_opt"]
    
    # Add do commands for simulation
    do_commands = []
    
    if args.dump:
        vcd_file = f"{args.name}.vcd"
        do_commands.extend([
            f'vcd file {vcd_file}',
            'vcd add -r /*',
            'vcd on'
        ])
    
    do_commands.extend([
        'run -all',
        'quit -f'
    ])
    
    # Combine all do commands
    sim_cmd.extend(['-do', '; '.join(do_commands)])
    
    run_command(sim_cmd, f"Running simulation", f"{args.name}_simulate.log")
    
    print(f"\n{'='*60}")
    print("✓ All steps completed successfully!")
    print(f"\nGenerated log files:")
    print(f"  - {args.name}_vlib.log (if library was created)")
    print(f"  - {args.name}_compile_design.log")
    print(f"  - {args.name}_compile_tb.log")
    print(f"  - {args.name}_elaborate.log")
    print(f"  - {args.name}_simulate.log")
    if args.dump:
        print(f"\n✓ Waveform dump saved to: {args.name}.vcd")
    print('='*60)

if __name__ == "__main__":
    main()