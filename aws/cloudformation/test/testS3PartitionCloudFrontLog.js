const LambdaTester = require( 'lambda-tester' );
const AWS = require('aws-sdk');
const sinon = require('sinon');
process.env.ATHENA_DB = 'athena_db';
process.env.ATHENA_TABLE = 'athena_table';
process.env.ATHENA_OUTPUT = 'athena_output';

describe( 'handler', ()=> {
  let sandbox;
  let s3;
  let athena;
  let ok = {promise: () => Promise.resolve('OK')};
  beforeEach ((done) => {
    sandbox = sinon.createSandbox();
    let s3API = {
      copyObject: () => {},
      deleteObject: () => {}
    };
    let athenaAPI = {
      startQueryExecution: () => {}
    };
    s3 = sandbox.mock(s3API);
    athena = sandbox.mock(athenaAPI);
    sandbox.stub(AWS, 'S3').returns(s3API);
    sandbox.stub(AWS, 'Athena').returns(athenaAPI);
    done();
  });
  afterEach((done) => {
    sandbox.restore();
    done();
  });

  const filename = "[ID].YYYY-MM-DD-HH.[Hash].gz";
  const bucket = "sourcebucket";
  const prefix = "prefix";

  // Ref: https://docs.aws.amazon.com/lambda/latest/dg/eventsources.html#eventsources-s3-put
  const event = {
    "Records": [
      {
        "s3": {
          "object": { "key": `${prefix}/${filename}` },
          "bucket": { "name": bucket }
        }
      }
    ]
  };

  it('works', () => {
    const myHandler = require( '../s3PartitionCloudFrontLog' ).handler;
    s3.expects('copyObject').withArgs({
      CopySource: `${bucket}/${prefix}/${filename}`,
      Bucket: bucket,
      Key: `cloudfront/${prefix}/year=YYYY/month=MM/day=DD/hour=HH/${filename}`
    }).once().returns(ok);
    s3.expects('deleteObject').withArgs({
      Bucket: bucket,
      Key: `${prefix}/${filename}`
    }).once().returns(ok);
    const testPartition = "year = 'YYYY', month = 'MM', day = 'DD', hour = 'HH'";
    const testLocation = `s3://${bucket}/cloudfront/${prefix}/year=YYYY/month=MM/day=DD/hour=HH`;
    athena.expects('startQueryExecution').withArgs({
      QueryString: `ALTER TABLE ${process.env.ATHENA_TABLE} ADD IF NOT EXISTS PARTITION (${testPartition}) LOCATION '${testLocation}'`,
      ResultConfiguration: {
        OutputLocation: process.env.ATHENA_OUTPUT
      },
      QueryExecutionContext: {
        Database: process.env.ATHENA_DB
      }
    }).once().returns(ok);
    return LambdaTester(myHandler)
      .event(event)
      .expectResult(result => {
        s3.verify();
      });
  });
});
