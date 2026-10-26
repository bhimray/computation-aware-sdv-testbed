#!/bin/bash -l

#SBATCH --job-name=sdv_mains
#SBATCH --partition=normal
#SBATCH --array=0-2%3
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --mem=16G
#SBATCH --time=2-00:00:00
#SBATCH --output=hpc/slurm_logs/%x_%A_%a.out
#SBATCH --error=hpc/slurm_logs/%x_%A_%a.err
#SBATCH --no-requeue

set -euo pipefail

# Repository location
export PROJECT_ROOT="${SLURM_SUBMIT_DIR}"

if [[ ! -f "${PROJECT_ROOT}/startup_project.m" ]]; then
    echo "Submit this job from the SDV repository root."
    echo "Current submission directory: ${PROJECT_ROOT}"
    exit 10
fi

module purge

MATLAB_MODULE="${SDV_MATLAB_MODULE:-matlab/r2024b}"

module load gnu13
module load "${MATLAB_MODULE}"
module list

# Restrict numerical libraries to one physical core.
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export MKL_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export OPENBLAS_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export NUMEXPR_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export OMP_PROC_BIND=true
export OMP_PLACES=cores

# Persistent acados installation.
export SDV_ACADOS_ROOT="${HOME}/work/sdv_dependencies/acados/v0.5.4"
export ACADOS_INSTALL_DIR="${SDV_ACADOS_ROOT}"

# Generated project-specific solver.
export SOLVER_DIR="${PROJECT_ROOT}/build/acados/sdv_dynamic_bicycle"

export LD_LIBRARY_PATH="${SOLVER_DIR}:${SDV_ACADOS_ROOT}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export PATH="${SDV_ACADOS_ROOT}/bin:${PATH}"

SOLVER_FILE="${SOLVER_DIR}/acados_solver_sfunction_sdv_dynamic_bicycle.mexa64"

if [[ ! -f "${SOLVER_FILE}" ]]; then
    echo "Linux acados S-function is missing:"
    echo "${SOLVER_FILE}"
    echo "Generate it once on Juno before submitting the sweep."
    exit 20
fi

# Separate runtime folders for each array element.
TASK_SCRATCH="${SLURM_TMPDIR:-/tmp/${USER}}/sdv_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"

mkdir -p "${TASK_SCRATCH}/prefs"
mkdir -p "${TASK_SCRATCH}/tmp"
mkdir -p "${TASK_SCRATCH}/simulink_cache"
mkdir -p "${TASK_SCRATCH}/code_generation"

export SDV_TASK_SCRATCH="${TASK_SCRATCH}"
export MATLAB_PREFDIR="${TASK_SCRATCH}/prefs"
export TMPDIR="${TASK_SCRATCH}/tmp"

cd "${PROJECT_ROOT}"

echo "Host:             $(hostname)"
echo "Project root:     ${PROJECT_ROOT}"
echo "Array task:       ${SLURM_ARRAY_TASK_ID}"
echo "Allocated CPUs:   ${SLURM_CPUS_PER_TASK}"
echo "Allocated memory: ${SLURM_MEM_PER_NODE:-unknown}"
echo "MATLAB module:    ${MATLAB_MODULE}"
echo "acados root:      ${SDV_ACADOS_ROOT}"
echo "Solver file:      ${SOLVER_FILE}"
echo "Task scratch:     ${TASK_SCRATCH}"

srun --cpu-bind=verbose,cores \
    matlab \
    -singleCompThread \
    -batch \
    "addpath(fullfile(getenv('PROJECT_ROOT'),'hpc')); run_juno_main();"