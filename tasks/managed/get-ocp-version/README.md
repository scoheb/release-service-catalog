# get-ocp-version

Tekton task to collect OCP version tag from FBC fragment using `skopeo inspect`.

## Parameters

| Name          | Description                                                                | Optional | Default value |
|---------------|----------------------------------------------------------------------------|----------|---------------|
| snapshotPath  | Path to the JSON string of the mapped Snapshot spec in the data workspace  | No       | -             | 

## Changes in 1.0.0
* Using new parameter, snapshotPath, obtain the fbcFragment directly.

## Changes in 0.5.2
* Bump the utils image used in this task
  * The `get-image-architectures` script now uses `set -e` so that it fails
    if a `skopeo` or `oras` call fails

## Changes in 0.5.1
* Task updated to handle multi-arch fbc fragments

## Changes in 0.5.0
* Updated the base image used in this task

## Changes in 0.4.0
* Updated the base image used in this task

## Changes in 0.2.0
* Updated hacbs-release/release-utils image to reference redhat-appstudio/release-service-utils image instead

## Changes in 0.1
* update Tekton API to v1
