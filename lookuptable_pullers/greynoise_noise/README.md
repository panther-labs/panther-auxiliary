## GreyNoise Lookup Table puller
Panther supports enriching logs as they are processed through the Panther detection system with [Lookup Tables](https://docs.panther.com/enrichment) (LUTs). By using GreyNoise as an [indicator feed](https://docs.greynoise.io/docs/using-greynoise-as-an-indicator-feed)), we can construct a Panther Lookup Table containing the current GreyNoise Noise data set for enrichment.

This directory contains the necessary script to pull the GreyNoise data as an indicator feed, as well as the necessary Panther and AWS assets needed to get those into Panther as a Lookup Table.

## How to setup GreyNoise LUT puller

Setting up the GreyNoise LUT puller consists of three steps:
- Configuring the script to run
- Getting the data to S3
- Configuring Panther to pull the data

### Configuring the script to run

The script uses all standard Python libraries except for the GreyNoise python sdk, which you can install with the following command:

`pip3 install greynoise`

To configure the script, you need to copy your GreyNoise API token into the `API_TOKEN` variable at the top of the `puller.py` script.


That's it! The script can now be run to generate the necessary lookup table artifact with the following command:

`python3 puller.py`

or you can make the script executable with `chmod +x puller.py` and just run with:

`./puller.py`

If you don't like staring at a blank screen waiting for it to work, you can set the logging level to INFO and the script will show what page of results you are on:

`./puller.py -log INFO`

Note that if you run the puller script from a location with the output of a previous script run, it will only pull the last few days and combine that with the output of the last result. This should result in faster subsequent runs. However, if you don't have a persistent data store to run this script that's fine as it will recompute the entire last 7 days if it does not find the ouput of a previous run.


### Getting the data to S3

Create an S3 bucket in your AWS account and upload the `greynoise_noise_lut.jsonl` file to it.

This can be automated using the AWS CLI or using a python script with boto3.

### Configuring the lookup table in Panther

1. Setup AWS permissions
  - Go to the AWS account that is hosting your data in S3 and create an IAM role using the CFN template `panther-lookup-role.yml`. This template is also hosted publicly [here](https://github.com/panther-labs/panther-auxiliary/blob/main/cloudformation/panther-s3-lookups-iam.yml). Either before uploading the template (if using the mappings) or when prompted by the CloudFormation wizard, specify the following parameters:
    - For `MasterAccountId`, put the account where your Panther instance is running (accessible from the General settings page)
    - For `RoleSuffix`, specify any value. This is to uniquely identify this role from other potential roles you might setup similar to this one.
    - For `S3Bucket`, specify just the name (not ARN) of the S3 bucket where you uploaded your data
    - For `S3Object`, specify the object name (with full path) of your uploaded data
    - For `KmsKey`, if you have KMS key encryption enabled for this bucket specify the key arn
  - Save the role ARN from the outputs tab for later
2. Create the lookup table in Panther
  - Edit the following fields in `greynoise_noise_advanced.yml`:
    - `Schema`: choose `GreyNoise.API.Noise`
    - `RoleARN`: enter the arn of your role from step 1
    - `ObjectPath`: enter the full object path for the file you uploaded, using the format `s3://{bucket_name}/{object_name}`
    - `ObjectKMSKey`: if you are using KMS key encryption, enter the ARN of the KMS key here
  - Use the `panther_analysis_tool zip` command, or just manually add the `greynoise_noise_advanced.yml` file to a zip archive
  - In the Panther Console, go to Build -> Bulk Uploader page and upload the zip file

After a moment, the upload should show a success. You can then navigate to Configure -> Lookup Tables to view  your newly created lookup table. The `Entries` section might show 0 initially, you can click the `Sync` button and wait a few minutes then refresh the page and you should see some number of entries populate equal to the number of lines in your `greynoise_noise_lut.jsonl` file. After you see entries there, you can click the three dots and select "view in data explorer" to preview the logs.
