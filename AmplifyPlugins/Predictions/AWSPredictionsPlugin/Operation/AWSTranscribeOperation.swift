//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient
import AWSPluginsCore

public class AWSTranscribeOperation: AmplifyOperation<PredictionsSpeechToTextRequest,
    Void,
    SpeechToTextResult,
    PredictionsError>,
PredictionsSpeechToTextOperation {

    let multiService: TranscribeMultiService

    init(request: PredictionsSpeechToTextRequest,
         multiService: TranscribeMultiService,
         listener: EventListener?) {
        self.multiService = multiService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.speechToText,
                   request: request,
                   listener: listener)
    }

    override public func main() {

        if let error = request.validate() {
            dispatch(event: .failed(error))
            finish()
            return
        }
        multiService.setRequest(request)
        switch request.options.defaultNetworkPolicy {
        case .offline:
            multiService.fetchOfflineResult(callback: { event in
                self.onServiceEvent(event: event)
            })
        case .auto:
            multiService.fetchMultiServiceResult(callback: { event in
                self.onServiceEvent(event: event)
            })
        }
    }

    private func onServiceEvent(event: PredictionsEvent<SpeechToTextResult, PredictionsError>) {
        switch event {
        case .completed(let result):
            dispatch(event: .completed(result))
            finish()
        case .failed(let error):
            dispatch(event: .failed(error))
            finish()
        }
    }
}