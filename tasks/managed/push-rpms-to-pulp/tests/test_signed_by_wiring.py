"""Verify the RPM pipeline passes its signing alias to signed Pulp uploads."""

import json
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[4]
PIPELINE = ROOT / "pipelines/managed/push-rpms-to-pulp/push-rpms-to-pulp.yaml"
TASK = ROOT / "tasks/managed/push-rpms-to-pulp/push-rpms-to-pulp.yaml"


class TestSignedByWiring(unittest.TestCase):
    def test_signed_upload_receives_alias_from_release_data(self):
        pipeline = yaml.safe_load(PIPELINE.read_text(encoding="utf-8"))
        task = yaml.safe_load(TASK.read_text(encoding="utf-8"))
        pipeline_tasks = {item["name"]: item for item in pipeline["spec"]["tasks"]}
        collect_params = {
            item["name"]: item["value"]
            for item in pipeline_tasks["collect-task-params"]["params"]
        }
        keys = json.loads(collect_params["keysToExtract"])
        alias = next(item for item in keys if item["key"] == ".signOptions.signKeyAlias.key")

        signed_params = {
            item["name"]: item["value"]
            for item in pipeline_tasks["push-signed-rpms-to-pulp"]["params"]
        }
        self.assertEqual(
            signed_params["signedBy"],
            f"$(tasks.collect-task-params.results.extractedValues[{alias['resultIndex']}])",
        )

        task_params = {item["name"]: item for item in task["spec"]["params"]}
        self.assertEqual(task_params["signedBy"]["default"], "")
        task_env = {item["name"]: item["value"] for item in task["spec"]["stepTemplate"]["env"]}
        self.assertEqual(task_env["SIGNED_BY"], "$(params.signedBy)")


if __name__ == "__main__":
    unittest.main()
