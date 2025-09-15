#!/usr/bin/env bash
set -ex

# mocks to be injected into task step scripts

function pulp() {
    echo $* >> $(params.dataDir)/mock_pulp.txt
    if [[ "$*" == *"domain show"* ]]; then
        echo "{ \"name\": \"mydomain\" }"
    elif [[ "$*" == *"rpm repository list"* ]]; then
        echo "[ {\"name\": \"x86_64\"}, {\"name\": \"ppc64le\"}, {\"name\": \"s390x\"}, {\"name\": \"aarch64\"}, {\"name\": \"source\"} ]"
    elif [[ "$*" == *"rpm content upload"* ]]; then
        echo "Uploaded"
    else
        echo Error: Unexpected call
        exit 1
    fi
}

function select-oci-auth() {
    echo Mock select-oci-auth called with: $*
}

function oras() {
    echo Mock oras called with: $*
    echo $* >> $(params.dataDir)/mock_oras.txt
    local args="$*"

    if [[ "$*" == "pull --registry-config"* ]]; then
        echo "Mocking pulling files"

        # Initialize a variable to store the value of the -o flag.
        output_file_dir=""

        # Loop through all arguments passed to the script.
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -o|--output)
                    # Check if there is a next argument to capture.
                    if [[ -n "$2" ]]; then
                        # Capture the value of the next argument and store it.
                        output_file_dir="$2"
                        # Shift twice to move past both the flag and its value.
                        shift 2
                    fi
                    ;;
                *)
                    # For any other arguments, just shift past them.
                    shift
                    ;;
            esac
        done

        # Check if the output_file variable was successfully populated.
        if [[ -n "$output_file_dir" ]]; then
            echo "The captured output file dir is: $output_file_dir"
        fi

        if [[ "$args" == *"quay.io/test/happypath"* ]]; then
            touch $output_file_dir/hello-2.12.1-6.fc44.aarch64.rpm
            touch $output_file_dir/hello-2.12.1-6.fc44.ppc64le.rpm
            touch $output_file_dir/hello-2.12.1-6.fc44.s390x.rpm
            touch $output_file_dir/hello-2.12.1-6.fc44.src.rpm
            touch $output_file_dir/hello-2.12.1-6.fc44.x86_64.rpm
            touch $output_file_dir/hello-docs-2.12.1-6.fc44.noarch.rpm
            touch $output_file_dir/hello-debuginfo-2.12.1-6.fc44.aarch64.rpm
            touch $output_file_dir/hello-debuginfo-2.12.1-6.fc44.ppc64le.rpm
            touch $output_file_dir/hello-debuginfo-2.12.1-6.fc44.s390x.rpm
            touch $output_file_dir/hello-debuginfo-2.12.1-6.fc44.x86_64.rpm
            touch $output_file_dir/hello-debugsource-2.12.1-6.fc44.aarch64.rpm
            touch $output_file_dir/hello-debugsource-2.12.1-6.fc44.ppc64le.rpm
            touch $output_file_dir/hello-debugsource-2.12.1-6.fc44.s390x.rpm
            touch $output_file_dir/hello-debugsource-2.12.1-6.fc44.x86_64.rpm
            # mimic having logs from each rpm build
            mkdir -p $output_file_dir/logs
            touch $output_file_dir/logs/hello-2.12.1-6.fc44.aarch64.rpm.log
            touch $output_file_dir/logs/hello-2.12.1-6.fc44.ppc64le.rpm.log
            touch $output_file_dir/logs/hello-2.12.1-6.fc44.s390x.rpm.log
            touch $output_file_dir/logs/hello-2.12.1-6.fc44.src.rpm.log
            touch $output_file_dir/logs/hello-2.12.1-6.fc44.x86_64.rpm.log
            touch $output_file_dir/logs/hello-debuginfo-2.12.1-6.fc44.aarch64.rpm.log
        elif [[ "$args" == *"quay.io/test/onlyrpms"* ]]; then
            touch $output_file_dir/hello-2.12.1-6.fc44.x86_64.rpm
            touch $output_file_dir/hello-debuginfo-2.12.1-6.fc44.x86_64.rpm
            touch $output_file_dir/hello-debugsource-2.12.1-6.fc44.x86_64.rpm
            # mimic having logs from each rpm build
            mkdir -p $output_file_dir/logs
            touch $output_file_dir/logs/hello-2.12.1-6.fc44.x86_64.rpm.log
            touch $output_file_dir/logs/hello-debuginfo-2.12.1-6.fc44.x86_64.rpm.log
            touch $output_file_dir/logs/hello-debugsource-2.12.1-6.fc44.x86_64.rpm.log
        else
            echo Error: Unexpected call
            exit 1
        fi

    fi
}
