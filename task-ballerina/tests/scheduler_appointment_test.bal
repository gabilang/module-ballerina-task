// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/lang.runtime as runtime;
import ballerina/test;

const APPOINTMENT_MULTI_SERVICE_SUCCESS_RESPONSE = "Multiple services invoked";
const LIMITED_RUNS_SUCCESS_RESPONSE = "Scheduler triggered limited times";
const APPOINTMENT_FAILURE_RESPONSE = "Services failed to trigger";

boolean appoinmentFirstTriggered = false;
boolean appoinmentSecondTriggered = false;
int appoinmentTriggerCount1 = 0;
int appoinmentTriggerCount2 = 0;
int appoinmentTriggerCount3 = 0;

service object {}appointmentService1 = service object {
    remote function onTrigger() {
        appoinmentTriggerCount1 += 1;
        if (appoinmentTriggerCount1 > 3) {
            appoinmentFirstTriggered = true;
        }
    }
};

service object {} appointmentService2 = service object {
    remote function onTrigger() {
        appoinmentTriggerCount2 += 1;
        if (appoinmentTriggerCount2 > 3) {
            appoinmentSecondTriggered = true;
        }
    }
};

service object {} appointmentService3 = service object {
    remote function onTrigger() {
        appoinmentTriggerCount3 += 1;
    }
};

@test:Config {
    groups: ["scheduler", "multiple service", "cron"]
}
function testSchedulerWithMultipleServices() returns error? {
    string cronExpression = "* * * * * ? *";
    Scheduler appointment = check new ({cronExpression: cronExpression});
    checkpanic appointment.attach(appointmentService1);
    checkpanic appointment.attach(appointmentService2);
    checkpanic appointment.start();
    runtime:sleep(4);
    checkpanic appointment.stop();
    test:assertTrue(appoinmentFirstTriggered, msg = "Expected value mismatched");
    test:assertTrue(appoinmentSecondTriggered, msg = "Expected value mismatched");
}

@test:Config {
    groups: ["scheduler", "count", "cron"]
}
function testLimitedNumberOfRuns() returns error? {
    string cronExpression = "* * * * * ? *";
    AppointmentConfiguration configuration = {
        cronExpression: cronExpression,
        noOfRecurrences: 3
    };
    Scheduler appointmentWithLimitedRuns = check new (configuration);
    var result = appointmentWithLimitedRuns.attach(appointmentService3);
    checkpanic appointmentWithLimitedRuns.start();
    runtime:sleep(5);
    checkpanic appointmentWithLimitedRuns.stop();
    test:assertEquals(appoinmentTriggerCount3, 3, msg = "Expected value mismatched");
}
