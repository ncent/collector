# Collector

Contains the terraform configuration files to setup a collector

## Configuration

First create a file with name `terraform.tfvars` this file will store the sensive variables and useful variables (this file isn't versionated)

```bash
# Stage to deploy
stage = "development"

# Your AWS profile configuration on credentials file
profile = "default"

# Region to deploy
region = ""

# RedShift password
redshift_passwd = ""
```

## Building the infra

```bash
# On terminal
terraform init

# Then apply the configuration and confirm if ok
terraform apply
```

## Destroying the infra

```bash
# If you want to destroy everything
terraform destroy
```

## RedShift tables

The table `challenge_usage_quota` will receive the challenge deatails and user information about the challenge to track the challenge usage quota

```sql
create table challenge_usage_quota
(
  uuid varchar
  action varchar
  timestamp timestamp
);
```

## JSON paths

The file describe the structure that will be transformed from JSON to the fields used on table `challenge_usage_quota`

```json
{
  "jsonpaths": [
    "$.detail.uuid",
    "$.detail.action",
    "$.detail.timestamp"
  ]
}
```

## Querying user quota

The query `quota_count` is created on the server to help to check the current usage quota of the user

```sql
PREPARE quota_count (VARCHAR, VARCHAR, VARCHAR) AS
    SELECT
        COUNT(*)
    FROM
        challenge_usage_quota
    WHERE
        challenge_usage_quota.uuid = $1
        AND action = $2
        AND timestamp between (GETDATE() - $3 ::INTERVAL)
        AND GETDATE();
```

> Obs.: Between acts like `value >= low and value <= high`

For instance query for the user `4321-abcd`, which has the criteria of 5 challenges created per day

```sql
EXECUTE quota_count('4321-abcd', 'created', '1 DAY')
```

Returns `5`, so the user `4321-abcd` reached his current quota and will wait for the cooldown period before back into create challenges again.

Same logic can be applied for `shared` challenges, just replace the second parameter of the function

```sql
EXECUTE quota_count('4321-abcd', 'shared', '1 DAY')
```

## Authors

* **Rodrigo Serviuc Pavezi** - *Initial work* - [rodrigopavezi](https://gitlab.com/rodrigopavezi)
* **Eduardo Nunes Pereira** - [eduardonunesp](https://gitlab.com/eduardonunesp)
* **Arya Soltanieh** - [lostcodingsomewhere](https://gitlab.com/lostcodingsomewhere)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
