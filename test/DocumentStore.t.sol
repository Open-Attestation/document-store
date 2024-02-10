// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "../src/DocumentStore.sol";
import "../src/interfaces/IDocumentStore.sol";
import "../src/interfaces/IDocumentStoreBatchable.sol";
import "./CommonTest.t.sol";

contract DocumentStore_init_Test is CommonTest {
  function testDocumentName() public {
    assertEq(documentStore.name(), storeName);
  }

  function testOwnerIsAdmin() public view {
    assert(documentStore.hasRole(documentStore.DEFAULT_ADMIN_ROLE(), owner));
  }

  function testOwnerIsIssuer() public view {
    assert(documentStore.hasRole(documentStore.ISSUER_ROLE(), owner));
  }

  function testOwnerIsRevoker() public view {
    assert(documentStore.hasRole(documentStore.REVOKER_ROLE(), owner));
  }

  function testFailZeroOwner() public {
    documentStore = new DocumentStore(storeName, vm.addr(0));
  }
}

contract DocumentStore_issue_Test is CommonTest {
  function setUp() public override {
    super.setUp();
  }

  function testIssueByOwner(bytes32 docHash) public {
    vm.assume(docHash != bytes32(0));
    vm.expectEmit(true, true, true, true);

    emit IDocumentStore.DocumentIssued(docHash);

    vm.prank(owner);
    documentStore.issue(docHash);

    assert(documentStore.isIssued(docHash));
  }

  function testIssueByIssuer(bytes32 docHash) public {
    vm.assume(docHash != bytes32(0));
    vm.expectEmit(true, true, true, true);

    emit IDocumentStore.DocumentIssued(docHash);

    vm.prank(issuer);
    documentStore.issue(docHash);

    assert(documentStore.isIssued(docHash));
  }

  function testIssueByRevokerRevert(bytes32 docHash) public {
    vm.assume(docHash != bytes32(0));
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        revoker,
        documentStore.ISSUER_ROLE()
      )
    );

    vm.prank(revoker);
    documentStore.issue(docHash);
  }

  function testIssueByNonIssuerRevert(bytes32 docHash) public {
    vm.assume(docHash != bytes32(0));
    address notIssuer = vm.addr(69);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        notIssuer,
        documentStore.ISSUER_ROLE()
      )
    );

    vm.prank(notIssuer);
    documentStore.issue(docHash);
  }

  function testIssueAlreadyIssuedRevert(bytes32 docHash) public {
    vm.assume(docHash != bytes32(0));
    vm.startPrank(issuer);
    documentStore.issue(docHash);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentExists.selector, bytes32(docHash)));

    documentStore.issue(docHash);
    vm.stopPrank();
  }

  function testIssueZeroDocument() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    vm.prank(issuer);
    documentStore.issue(0x0);
  }
}

contract DocumentStore_multicallIssue_Test is CommonTest {
  bytes32[] public docHashes;

  bytes[] public bulkIssueData;

  function setUp() public override {
    super.setUp();

    docHashes = new bytes32[](2);
    docHashes[0] = "0x1234";
    docHashes[1] = "0x5678";

    bulkIssueData = new bytes[](2);
    bulkIssueData[0] = abi.encodeCall(IDocumentStore.issue, (docHashes[0]));
    bulkIssueData[1] = abi.encodeCall(IDocumentStore.issue, (docHashes[1]));
  }

  function testBulkIssueByIssuer() public {
    vm.expectEmit(true, false, false, true);
    emit IDocumentStore.DocumentIssued(docHashes[0]);
    vm.expectEmit(true, false, false, true);
    emit IDocumentStore.DocumentIssued(docHashes[1]);

    vm.prank(issuer);
    documentStore.multicall(bulkIssueData);

    assert(documentStore.isIssued(docHashes[0]));
    assert(documentStore.isIssued(docHashes[1]));
  }

  function testBulkIssueByNonIssuerRevert() public {
    address notIssuer = vm.addr(69);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        notIssuer,
        documentStore.ISSUER_ROLE()
      )
    );

    vm.prank(notIssuer);
    documentStore.multicall(bulkIssueData);
  }

  function testBulkIssueWithDuplicatesRevert() public {
    docHashes[1] = docHashes[0];
    bulkIssueData[1] = abi.encodeCall(IDocumentStore.issue, (docHashes[0]));

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentExists.selector, bytes32(docHashes[1])));

    vm.prank(issuer);
    documentStore.multicall(bulkIssueData);
  }
}

contract DocumentStore_isIssued_Test is BatchedDocuments_Initializer {
  function testIsRootIssuedWithRoot() public {
    assertTrue(documentStore.isIssued(docRoot));
  }

  function testIsRootIssuedWithZeroRoot() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    documentStore.isIssued(0x0);
  }

  function testIsIssuedWithRoot() public {
    assertTrue(documentStore.isIssued(docRoot, docRoot, new bytes32[](0)));
  }

  function testIsIssuedWithValidProof() public {
    assertTrue(documentStore.isIssued(docRoot, documents[0], proofs[0]));
    assertTrue(documentStore.isIssued(docRoot, documents[1], proofs[1]));
    assertTrue(documentStore.isIssued(docRoot, documents[2], proofs[2]));
  }

  function testIsIssuedWithInvalidProof() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, documents[1]));

    documentStore.isIssued(docRoot, documents[1], proofs[0]);
  }

  function testIsIssuedWithInvalidEmptyProof() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, documents[1]));

    documentStore.isIssued(docRoot, documents[1], new bytes32[](0));
  }

  function testIsIssuedWithZeroDocument() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));
    documentStore.isIssued(0x0, documents[0], proofs[0]);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));
    documentStore.isIssued(docRoot, 0x0, proofs[0]);
  }
}

contract DocumentStore_revokeRoot_Test is BatchedDocuments_Initializer {
  function testRevokeRootByOwner() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, docRoot);

    vm.prank(owner);
    documentStore.revoke(docRoot);

    assertTrue(documentStore.isRevoked(docRoot));
  }

  function testRevokeRootByRevoker() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, docRoot);

    vm.prank(revoker);
    documentStore.revoke(docRoot);

    assertTrue(documentStore.isRevoked(docRoot));
  }

  function testRevokeRootByIssuerRevert() public {
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        issuer,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(issuer);
    documentStore.revoke(docRoot);
  }

  function testRevokeRootByNonRevokerRevert() public {
    address notRevoker = vm.addr(69);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        notRevoker,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(notRevoker);
    documentStore.revoke(docRoot);
  }

  function testRevokeRootWithZeroRoot() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    vm.prank(revoker);
    documentStore.revoke(0x0);
  }

  function testRevokeRootAlreadyRevokedRevert() public {
    vm.startPrank(revoker);
    documentStore.revoke(docRoot);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InactiveDocument.selector, docRoot, docRoot));

    documentStore.revoke(docRoot);
    vm.stopPrank();
  }

  function testRevokeRootNonIssuedRootRevert(bytes32 nonIssuedRoot) public {
    vm.assume(nonIssuedRoot != docRoot && nonIssuedRoot != bytes32(0));

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentNotIssued.selector, nonIssuedRoot, nonIssuedRoot));

    vm.prank(revoker);
    documentStore.revoke(nonIssuedRoot);
  }
}

contract DocumentStoreBatchable_revoke_Test is BatchedDocuments_Initializer {
  function testRevokeByOwner() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, documents[0]);

    vm.prank(owner);
    documentStore.revoke(docRoot, documents[0], proofs[0]);

    assertTrue(documentStore.isRevoked(docRoot, documents[0], proofs[0]));
  }

  function testRevokeByRevoker() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, documents[0]);

    vm.prank(revoker);
    documentStore.revoke(docRoot, documents[0], proofs[0]);

    assertTrue(documentStore.isRevoked(docRoot, documents[0], proofs[0]));
  }

  function testRevokeByIssuerRevert() public {
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        issuer,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(issuer);
    documentStore.revoke(docRoot, documents[0], proofs[0]);
  }

  function testRevokeByNonRevokerRevert() public {
    address notRevoker = vm.addr(69);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        notRevoker,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(notRevoker);
    documentStore.revoke(docRoot, documents[0], proofs[0]);
  }

  function testRevokeWithInvalidProofRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, documents[0]));

    vm.prank(revoker);
    documentStore.revoke(docRoot, documents[0], proofs[1]);
  }

  function testRevokeWithEmptyProofRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, documents[0]));

    vm.prank(revoker);
    documentStore.revoke(docRoot, documents[0], new bytes32[](0));
  }

  function testRevokeWithZeroDocument() public {
    vm.startPrank(revoker);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));
    documentStore.revoke(0x0, documents[0], proofs[0]);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));
    documentStore.revoke(docRoot, 0x0, proofs[0]);

    vm.stopPrank();
  }

  function testRevokeAlreadyRevokedRevert() public {
    vm.startPrank(revoker);

    documentStore.revoke(docRoot, documents[0], proofs[0]);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InactiveDocument.selector, docRoot, documents[0]));

    documentStore.revoke(docRoot, documents[0], proofs[0]);

    vm.stopPrank();
  }

  function testRevokeAlreadyRevokedRootRevert() public {
    vm.startPrank(revoker);

    documentStore.revoke(docRoot);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InactiveDocument.selector, docRoot, documents[0]));

    documentStore.revoke(docRoot, documents[0], proofs[0]);

    vm.stopPrank();
  }

  function testRevokeNonIssuedDocumentRevert(bytes32 nonIssuedRoot) public {
    vm.assume(nonIssuedRoot != docRoot && nonIssuedRoot != bytes32(0));

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentNotIssued.selector, nonIssuedRoot, nonIssuedRoot));

    vm.prank(revoker);
    documentStore.revoke(nonIssuedRoot);
  }
}

abstract contract DocumentStore_multicall_revoke_Base is BatchedDocuments_Initializer {
  bytes32[] public docRoots = new bytes32[](3);
  bytes[] public bulkRevokeData;

  function testMulticallRevokeByOwner() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots[0], documents[0]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots[1], documents[1]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots[2], documents[2]);

    vm.prank(owner);
    documentStore.multicall(bulkRevokeData);

    assertTrue(documentStore.isRevoked(docRoots[0], documents[0], proofs[0]));
    assertTrue(documentStore.isRevoked(docRoots[1], documents[1], proofs[1]));
    assertTrue(documentStore.isRevoked(docRoots[2], documents[2], proofs[2]));
  }

  function testMulticallRevokeByRevoker() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots[0], documents[0]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots[1], documents[1]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots[2], documents[2]);

    vm.prank(revoker);
    documentStore.multicall(bulkRevokeData);

    assertTrue(documentStore.isRevoked(docRoots[0], documents[0], proofs[0]));
    assertTrue(documentStore.isRevoked(docRoots[1], documents[1], proofs[1]));
    assertTrue(documentStore.isRevoked(docRoots[2], documents[2], proofs[2]));
  }

  function testMulticallRevokeByIssuerRevert() public {
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        issuer,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(issuer);
    documentStore.multicall(bulkRevokeData);
  }

  function testMulticallRevokeByNonRevokerRevert() public {
    address notRevoker = vm.addr(69);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        notRevoker,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(notRevoker);
    documentStore.multicall(bulkRevokeData);
  }

  function testMulticallRevokeWithDuplicatesRevert() public {
    // Make document0 and document1 with same data
    docRoots[1] = docRoots[0];
    documents[1] = documents[0];
    proofs[1] = proofs[0];
    bulkRevokeData[1] = abi.encodeCall(IDocumentStoreBatchable.revoke, (docRoots[0], documents[0], proofs[0]));

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InactiveDocument.selector, docRoots[1], documents[1]));

    vm.prank(revoker);
    documentStore.multicall(bulkRevokeData);
  }
}

contract DocumentStoreBatchable_multicall_revoke_Test is DocumentStore_multicall_revoke_Base {
  function setUp() public override {
    super.setUp();

    docRoots[0] = docRoot;
    docRoots[1] = docRoot;
    docRoots[2] = docRoot;

    bulkRevokeData = new bytes[](3);
    bulkRevokeData[0] = abi.encodeCall(IDocumentStoreBatchable.revoke, (docRoot, documents[0], proofs[0]));
    bulkRevokeData[1] = abi.encodeCall(IDocumentStoreBatchable.revoke, (docRoot, documents[1], proofs[1]));
    bulkRevokeData[2] = abi.encodeCall(IDocumentStoreBatchable.revoke, (docRoot, documents[2], proofs[2]));
  }
}

contract DocumentStore_multicall_revoke_Test is DocumentStore_multicall_revoke_Base {
  function setUp() public override {
    super.setUp();

    // Set up the document fixtures to be independent documents
    docRoots[0] = documents[0];
    docRoots[1] = documents[1];
    docRoots[2] = documents[2];

    // We want the documents to be independent, thus no need proofs
    proofs[0] = new bytes32[](0);
    proofs[1] = new bytes32[](0);
    proofs[2] = new bytes32[](0);

    vm.startPrank(issuer);
    documentStore.issue(docRoots[0]);
    documentStore.issue(docRoots[1]);
    documentStore.issue(docRoots[2]);
    vm.stopPrank();

    bulkRevokeData = new bytes[](3);
    bulkRevokeData[0] = abi.encodeCall(IDocumentStore.revoke, (documents[0]));
    bulkRevokeData[1] = abi.encodeCall(IDocumentStore.revoke, (documents[1]));
    bulkRevokeData[2] = abi.encodeCall(IDocumentStore.revoke, (documents[2]));
  }
}

contract DocumentStore_isRevoked_Test is BatchedDocuments_Initializer {
  function setUp() public override {
    super.setUp();

    vm.prank(revoker);
    documentStore.revoke(docRoot, documents[0], proofs[0]);
  }

  function testIsRevokedWithRevokedDocument() public {
    assertTrue(documentStore.isRevoked(docRoot, documents[0], proofs[0]));
  }

  function testIsRevokedWithRevokedRoot() public {
    vm.prank(revoker);
    documentStore.revoke(docRoot);

    assertTrue(documentStore.isRevoked(docRoot, documents[1], proofs[1]));
  }

  function testIsRevokedWithNotRevokedDocument() public {
    assertFalse(documentStore.isRevoked(docRoot, documents[1], proofs[1]));
  }

  function testIsRevokedWithInvalidProofRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, documents[0]));

    documentStore.isRevoked(docRoot, documents[0], proofs[1]);
  }

  function testIsRevokedWithEmptyProofRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, documents[0]));

    documentStore.isRevoked(docRoot, documents[0], new bytes32[](0));
  }

  function testIsRevokedWithZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));
    documentStore.isRevoked(docRoot, 0x0, proofs[0]);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));
    documentStore.isRevoked(0x0, documents[0], proofs[0]);
  }

  function testIsRevokedWithNotIssuedDocumentRevert() public {
    bytes32 notIssuedDoc = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, notIssuedDoc));

    documentStore.isRevoked(docRoot, notIssuedDoc, proofs[0]);
  }
}

contract DocumentStore_isRootRevoked is BatchedDocuments_Initializer {
  function setUp() public override {
    super.setUp();

    vm.prank(revoker);
    documentStore.revoke(docRoot);
  }

  function testIsRootRevokedWithRevokedRoot() public {
    assertTrue(documentStore.isRevoked(docRoot));
  }

  function testIsRootRevokedWithNotRevokedRoot(bytes32 notRevokedRoot) public {
    vm.assume(notRevokedRoot != docRoot && notRevokedRoot != bytes32(0));

    vm.prank(issuer);
    documentStore.issue(notRevokedRoot);

    assertFalse(documentStore.isRevoked(notRevokedRoot));
  }

  function testIsRootRevokedWithZeroRootRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    documentStore.isRevoked(0x0);
  }

  function testIsRootRevokedWithNotIssuedRootRevert(bytes32 notIssuedRoot) public {
    vm.assume(notIssuedRoot != docRoot && notIssuedRoot != bytes32(0));

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentNotIssued.selector, notIssuedRoot, notIssuedRoot));

    assertFalse(documentStore.isRevoked(notIssuedRoot));
  }
}

contract DocumentStore_isActive_Test is BatchedDocuments_Initializer {
  function setUp() public override {
    super.setUp();

    vm.prank(revoker);
    documentStore.revoke(docRoot, documents[0], proofs[0]);
  }

  function testIsActiveWithActiveDocument() public {
    assertTrue(documentStore.isActive(docRoot, documents[1], proofs[1]));
  }

  function testIsActiveWithRevokedDocument() public {
    assertFalse(documentStore.isActive(docRoot, documents[0], proofs[0]));
  }

  function testIsActiveWithInvalidProofRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, documents[0]));

    documentStore.isActive(docRoot, documents[0], proofs[1]);
  }

  function testIsActiveWithEmptyProofRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, documents[0]));

    documentStore.isActive(docRoot, documents[0], new bytes32[](0));
  }

  function testIsActiveWithZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));
    documentStore.isActive(docRoot, 0x0, proofs[0]);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));
    documentStore.isActive(0x0, documents[0], proofs[0]);
  }

  function testIsActiveWithNotIssuedDocumentRevert(bytes32 notIssuedDoc) public {
    vm.assume(notIssuedDoc != docRoot && notIssuedDoc != bytes32(0));

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentNotIssued.selector, notIssuedDoc, notIssuedDoc));

    documentStore.isActive(notIssuedDoc, notIssuedDoc, new bytes32[](0));
  }

  function testIsActiveWithNotIssuedRootRevert() public {
    bytes32 notIssuedRoot = 0xb841229d504c5c9bcb8132078db8c4a483825ad811078144c6f9aec84213d798;
    bytes32 notIssuedDoc = 0xd56c26db0fde817dcd82269d0f9a3f50ea256ee0c870e43c3ec2ebdd655e3f37;

    bytes32[] memory proofs = new bytes32[](1);
    proofs[0] = 0x9800b3feae3c44fe4263f6cbb2d8dd529c26c3a1c3ca7208a30cfa5efbc362e7;

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentNotIssued.selector, notIssuedRoot, notIssuedDoc));

    documentStore.isActive(notIssuedRoot, notIssuedDoc, proofs);
  }
}
