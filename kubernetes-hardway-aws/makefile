# List all target scripts here
SCRIPTS := 01setup.sh 02certificate_authority.sh 03Kubeconfig.sh 04data_encription.sh 05boothstrapetch.sh 06bootstrap_cluster.sh 07bootstrap_worker.sh 08kubectl-node-acess.sh 09routes.sh 10inclusterdns.sh

# Default target, executes all numbered scripts
all: $(SCRIPTS)

# Pattern rule to execute scripts
$(SCRIPTS):
	sh $@

# Clean target
clean:
	rm -rf generated_files.txt

# .PHONY target to avoid conflicts with filenames
.PHONY: all $(SCRIPTS) clean
