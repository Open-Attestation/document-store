// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "../src/DocumentStore.sol";
import "../src/interfaces/IDocumentStore.sol";
import "../src/interfaces/IDocumentStoreBatchable.sol";
import "./CommonTest.t.sol";

contract DocumentStore_init_Test is DocumentStoreCommonTest {
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

contract DocumentStore_issue_Test is DocumentStoreCommonTest {
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

  function testIssueRevokedDocumentRevert(bytes32 docHash) public {
    vm.assume(docHash != bytes32(0));

    vm.startPrank(owner);
    documentStore.issue(docHash);
    documentStore.revoke(docHash);
    vm.stopPrank();

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentExists.selector, bytes32(docHash)));

    vm.prank(issuer);
    documentStore.issue(docHash);
  }

  function testIssueZeroDocument() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    vm.prank(issuer);
    documentStore.issue(0x0);
  }
}

contract DocumentStore_multicall_Issue_Test is DocumentStoreCommonTest {
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

contract DocumentStore_isIssued_Test is DocumentStoreBatchable_Initializer {
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

contract DocumentStore_revoke_Test is DocumentStore_Initializer {
  bytes32 internal targetDoc;

  function setUp() public override {
    super.setUp();

    targetDoc = documents[0];
  }

  function testRevokeByOwner() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(targetDoc, targetDoc);

    vm.prank(owner);
    documentStore.revoke(targetDoc);

    assertTrue(documentStore.isRevoked(targetDoc));
  }

  function testRevokeByRevoker() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(targetDoc, targetDoc);

    vm.prank(revoker);
    documentStore.revoke(targetDoc);

    assertTrue(documentStore.isRevoked(targetDoc));
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
    documentStore.revoke(targetDoc);
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
    documentStore.revoke(targetDoc);
  }

  function testRevokeWithZeroRoot() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    vm.prank(revoker);
    documentStore.revoke(0x0);
  }

  function testRevokeAlreadyRevokedRevert() public {
    vm.startPrank(revoker);
    documentStore.revoke(targetDoc);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InactiveDocument.selector, targetDoc, targetDoc));

    documentStore.revoke(targetDoc);
    vm.stopPrank();
  }

  function testRevokeNotIssuedRootRevert() public {
    bytes32 nonIssuedRoot = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentNotIssued.selector, nonIssuedRoot, nonIssuedRoot));

    vm.prank(revoker);
    documentStore.revoke(nonIssuedRoot);
  }
}

contract DocumentStore_multicall_revoke_Test is DocumentStore_multicall_revoke_Initializer {
  function setUp() public override {
    super.setUp();

    bulkRevokeData = new bytes[](3);
    bulkRevokeData[0] = abi.encodeCall(IDocumentStore.revoke, (documents()[0]));
    bulkRevokeData[1] = abi.encodeCall(IDocumentStore.revoke, (documents()[1]));
    bulkRevokeData[2] = abi.encodeCall(IDocumentStore.revoke, (documents()[2]));
  }
}

contract DocumentStore_isRevoked_Test is DocumentStore_Initializer {
  bytes32 public targetDocument;

  function setUp() public override {
    super.setUp();

    targetDocument = documents[0];

    vm.prank(revoker);
    documentStore.revoke(targetDocument);
  }

  function testIsRevokedWithRevokedDocument() public {
    assertTrue(documentStore.isRevoked(targetDocument));
  }

  function testIsRevokedWithNotRevokedDocument() public {
    assertFalse(documentStore.isRevoked(documents[2]));
  }

  function testIsRevokedWithZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    documentStore.isRevoked(0x0);
  }

  function testIsRevokedWithNotIssuedDocumentRevert() public {
    bytes32 notIssuedRoot = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentNotIssued.selector, notIssuedRoot, notIssuedRoot));

    documentStore.isRevoked(notIssuedRoot);
  }
}

contract DocumentStore_isActive_Test is DocumentStore_Initializer {
  function setUp() public override {
    super.setUp();

    vm.prank(revoker);
    documentStore.revoke(documents[0]);
  }

  function testIsActiveWithActiveDocument() public {
    assertTrue(documentStore.isActive(documents[1]));
  }

  function testIsActiveWithRevokedDocument() public {
    assertFalse(documentStore.isActive(documents[0]));
  }

  function testIsActiveWithZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));
    documentStore.isActive(0x0);
  }

  function testIsActiveWithNotIssuedDocumentRevert() public {
    bytes32 notIssuedDoc = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentNotIssued.selector, notIssuedDoc, notIssuedDoc));

    documentStore.isActive(notIssuedDoc);
  }
}

contract DocumentStore_supportsInterface_Test is DocumentStoreCommonTest {
  function testSupportsInterface() public {
    assertTrue(documentStore.supportsInterface(type(IDocumentStore).interfaceId));
    assertTrue(documentStore.supportsInterface(type(IDocumentStoreBatchable).interfaceId));
    assertTrue(documentStore.supportsInterface(type(IAccessControl).interfaceId));
  }
}
