//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AWSGraphQLOperation<R: Decodable>: GraphQLOperation<R> {

    let session: URLSessionBehavior
    let mapper: OperationTaskMapper
    let pluginConfig: AWSAPICategoryPluginConfiguration

    var graphQLResponseData = Data()

    init(request: GraphQLOperationRequest<R>,
         session: URLSessionBehavior,
         mapper: OperationTaskMapper,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         listener: AWSGraphQLOperation.EventListener?) {

        self.session = session
        self.mapper = mapper
        self.pluginConfig = pluginConfig

        super.init(categoryType: .api,
                   eventName: request.operationType.hubEventName,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        Amplify.API.log.debug("Starting \(request.operationType) \(id)")

        if isCancelled {
            finish()
            return
        }

        // Validate the request
        do {
            try request.validate()
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
            return
        } catch {
            dispatch(event: .failed(APIError.unknown("Could not validate request", "", nil)))
            finish()
            return
        }

        // Retrieve endpoint configuration
        let endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig
        do {
            endpointConfig = try pluginConfig.endpoints.getConfig(for: request.apiName, endpointType: .graphQL)
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
            return
        } catch {
            dispatch(event: .failed(APIError.unknown("Could not get endpoint configuration", "", nil)))
            finish()
            return
        }

        // Prepare request payload
        let queryDocument = GraphQLOperationRequestUtils.getQueryDocument(document: request.document,
                                                                          variables: request.variables)
        let requestPayload: Data
        do {
            requestPayload = try JSONSerialization.data(withJSONObject: queryDocument)
        } catch {
            dispatch(event: .failed(APIError.operationError("Failed to serialize query document",
                                                            "fix the document or variables",
                                                            error)))
            finish()
            return
        }

        // Create request
        let urlRequest = GraphQLOperationRequestUtils.constructRequest(with: endpointConfig.baseURL,
                                                                       requestPayload: requestPayload)

        // Intercept request
        let finalRequest = endpointConfig.interceptors.reduce(urlRequest) { (request, interceptor) -> URLRequest in
            do {
                return try interceptor.intercept(request)
            } catch {
                dispatch(event: .failed(APIError.operationError("Failed to intercept request fully..",
                                                                "Something wrong with the interceptor",
                                                                error)))
                cancel()
                return request
            }
        }

        if isCancelled {
            finish()
            return
        }

        // Begin network task
        Amplify.API.log.debug("Starting network task for \(request.operationType) \(id)")
        let task = session.dataTaskBehavior(with: finalRequest)
        mapper.addPair(operation: self, task: task)
        task.resume()
    }
}
