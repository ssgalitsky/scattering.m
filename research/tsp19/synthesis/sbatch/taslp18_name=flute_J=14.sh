# This shell script executes the Slurm jobs for computing reconstructions.

sbatch tsp19_name=flute_sc=none_J=14_wav=gammatone.sbatch
sbatch tsp19_name=flute_sc=none_J=14_wav=morlet.sbatch
sbatch tsp19_name=flute_sc=time_J=14_wav=gammatone.sbatch
sbatch tsp19_name=flute_sc=time_J=14_wav=morlet.sbatch
sbatch tsp19_name=flute_sc=time-frequency_J=14_wav=gammatone.sbatch
sbatch tsp19_name=flute_sc=time-frequency_J=14_wav=morlet.sbatch
