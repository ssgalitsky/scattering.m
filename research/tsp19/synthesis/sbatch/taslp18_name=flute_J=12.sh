# This shell script executes the Slurm jobs for computing reconstructions.

sbatch tsp19_name=flute_sc=none_J=12_wav=gammatone.sbatch
sbatch tsp19_name=flute_sc=none_J=12_wav=morlet.sbatch
sbatch tsp19_name=flute_sc=time_J=12_wav=gammatone.sbatch
sbatch tsp19_name=flute_sc=time_J=12_wav=morlet.sbatch
sbatch tsp19_name=flute_sc=time-frequency_J=12_wav=gammatone.sbatch
sbatch tsp19_name=flute_sc=time-frequency_J=12_wav=morlet.sbatch
