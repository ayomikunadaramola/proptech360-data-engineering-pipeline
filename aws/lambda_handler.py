import json
import boto3
import urllib.parse
from datetime import datetime, timezone

s3 = boto3.client("s3")


def lambda_handler(event, context):
    print("Received event:")
    print(json.dumps(event))

    processed = []

    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]

        key = urllib.parse.unquote_plus(
            record["s3"]["object"]["key"]
        )

        size = record["s3"]["object"].get("size", 0)

        etag = record["s3"]["object"].get(
            "eTag",
            record["s3"]["object"].get("etag")
        )

        print(f"Bucket: {bucket}")
        print(f"Key: {key}")
        print(f"Size: {size}")
        print(f"ETag: {etag}")

        # Safety check: only process objects inside raw/
        if not key.startswith("raw/"):
            print(f"Skipping object outside raw/: {key}")
            continue

        # Validate extension
        if not key.lower().endswith(".csv"):
            print(f"Skipping non-CSV object: {key}")
            continue

        # Validate non-empty object
        if size <= 0:
            raise ValueError(
                f"Invalid zero-byte object: {key}"
            )

        filename = key.split("/")[-1]

        audit_record = {
            "bucket": bucket,
            "source_key": key,
            "filename": filename,
            "size_bytes": size,
            "etag": etag,
            "event_time": record.get("eventTime"),
            "event_name": record.get("eventName"),
            "processed_at_utc": datetime.now(
                timezone.utc
            ).isoformat(),
            "status": "VALIDATED"
        }

        audit_key = (
            "audit/"
            + filename.replace(".csv", "")
            + "_audit.json"
        )

        s3.put_object(
            Bucket=bucket,
            Key=audit_key,
            Body=json.dumps(
                audit_record,
                indent=2
            ).encode("utf-8"),
            ContentType="application/json"
        )

        print(
            f"Audit record written to "
            f"s3://{bucket}/{audit_key}"
        )

        processed.append(audit_record)

        return {
            "statusCode": 200,
            "processed_count": len(processed),
            "processed": processed
        }