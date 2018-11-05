const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const athena = new AWS.Athena();

exports.handler = (event, context, callback) => {
  console.log("Request received:\n", JSON.stringify(event));
  process.on('uncaughtException', e=>callback(e));
  const bucket = event.Records[0].s3.bucket.name;
  const key = event.Records[0].s3.object.key;
  const keyFolder = key.split('/');
  const keyFilename = keyFolder.pop();
  // CloudFront log filename format: [ID].YYYY-MM-DD-HH.[Hash].gz
  const partitionNames = ['year', 'month', 'day', 'hour'];
  const date = keyFilename.split('.')[1].split('-');
  const partitionPrefix = date.map((v, i) => `${partitionNames[i]}=${v}`).join('/');
  const destinationBase = ['cloudfront', keyFolder.join('/'), partitionPrefix].filter(n => n).join('/');
  const destinationKey = [destinationBase, keyFilename].join('/');

  const partitionQuery = date.map((v, i) => `${partitionNames[i]} = '${v}'`).join(', ');
  const partitionLocation = `s3://${bucket}/${destinationBase}`;
  s3.copyObject({
    CopySource: [bucket, key].join('/'),
    Bucket: bucket,
    Key: destinationKey
  }).promise()
    .then((data)=>s3.deleteObject({
      Bucket: bucket,
      Key: key
    }).promise())
    .then((data)=>athena.startQueryExecution({
      QueryString: `ALTER TABLE ${process.env.ATHENA_TABLE} ADD IF NOT EXISTS PARTITION (${partitionQuery}) LOCATION '${partitionLocation}'`,
      ResultConfiguration: {
        OutputLocation: process.env.ATHENA_OUTPUT
      },
      QueryExecutionContext: {
        Database: process.env.ATHENA_DB
      }
    }).promise())
    .then((data)=>callback(null))
    .catch((e)=>callback(e));
};
