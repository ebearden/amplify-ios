//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class GraphQLDeleteMutationTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no required associations
    ///   - the mutation is of type `.delete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `deletePost`
    ///     - it contains an `input` of type `ID!`
    ///     - it has a list of fields with no nested models
    func testDeleteGraphQLMutationFromSimpleModel() {
        let post = Post(title: "title", content: "content", createdAt: Date())
        let document = GraphQLDeleteMutation(of: post)
        let expectedQueryDocument = """
        mutation DeletePost($input: DeletePostInput!, $condition: ModelPostConditionInput) {
          deletePost(input: $input, condition: $condition) {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "deletePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "deletePost")
        XCTAssert(document.variables["input"] != nil)
        guard let input = document.variables["input"] as? [String: String] else {
            XCTFail("Could not get object at `input`")
            return
        }
        XCTAssertEqual(input["id"], post.id)
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no required associations
    ///   - the mutation is of type `.delete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `deletePost`
    ///     - it contains an `input` of type `ID!`
    ///     - it has a list of fields with no nested models
    func testDeleteGraphQLMutationFromSimpleModelWithVersion() {
        let post = Post(title: "title", content: "content", createdAt: Date())
        let document = GraphQLDeleteMutation(of: post, syncEnabledVersion: 5)
        let expectedQueryDocument = """
        mutation DeletePost($input: DeletePostInput!, $condition: ModelPostConditionInput) {
          deletePost(input: $input, condition: $condition) {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.name, "deletePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "deletePost")
        XCTAssert(document.variables["input"] != nil)
        guard let input = document.variables["input"] as? [String: Any] else {
            XCTFail("Could not get object at `input`")
            return
        }
        XCTAssert(input["id"] as? String == post.id)
        XCTAssert(input["_version"] as? Int == 5)
    }
}
