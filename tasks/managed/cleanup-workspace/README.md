# cleanup-workspace

Tekton task to delete a given directory in a passed workspace and cleanup InternalRequests related to the current PipelineRun.

## Parameters

| Name           | Description                                                                                                      | Optional | Default value |
|----------------|------------------------------------------------------------------------------------------------------------------|----------|---------------|
| subdirectory   | The directory to remove within the workspace                                                                     | No       | -             |
| delay          | Time in seconds to delay execution. Needed to allow other finally tasks to access workspace before being deleted | Yes      | 60            |
| pipelineRunUid | The uid of the current pipelineRun. It is only available at the pipeline level                                   | Yes      | ""            |
