# This shell script executes the Slurm jobs for computing reconstructions.

sbatch tsp19_name=dog-bark_sc=none_J=13_wav=gammatone.sbatch
sbatch tsp19_name=dog-bark_sc=none_J=13_wav=morlet.sbatch
sbatch tsp19_name=dog-bark_sc=time_J=13_wav=gammatone.sbatch
sbatch tsp19_name=dog-bark_sc=time_J=13_wav=morlet.sbatch
sbatch tsp19_name=dog-bark_sc=time-frequency_J=13_wav=gammatone.sbatch
sbatch tsp19_name=dog-bark_sc=time-frequency_J=13_wav=morlet.sbatch
