// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import {console2} from "forge-std/console2.sol";
import "forge-std/Test.sol";
import "../src/DocumentStore.sol";
import "../src/interfaces/IDocumentStore.sol";

import "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract CommonTest is Test {
  string public storeName = "DocumentStore Test";

  address public owner = vm.addr(1);
  address public issuer = vm.addr(2);
  address public revoker = vm.addr(3);

  DocumentStore public documentStore;

  function setUp() public virtual {
    vm.startPrank(owner);

    documentStore = new DocumentStore(storeName, owner);
    documentStore.grantRole(documentStore.ISSUER_ROLE(), issuer);
    documentStore.grantRole(documentStore.REVOKER_ROLE(), revoker);

    vm.stopPrank();
  }
}

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
  bytes32 public docHash = "0x1234";

  function setUp() public override {
    super.setUp();
  }

  function testIssueByOwner() public {
    vm.expectEmit(true, true, true, true);

    emit IDocumentStore.DocumentIssued(docHash);

    vm.prank(owner);
    documentStore.issue(docHash);

    assert(documentStore.isRootIssued(docHash));
  }

  function testIssueByIssuer() public {
    vm.expectEmit(true, true, true, true);

    emit IDocumentStore.DocumentIssued(docHash);

    vm.prank(issuer);
    documentStore.issue(docHash);

    assert(documentStore.isRootIssued(docHash));
  }

  function testIssueByRevokerRevert() public {
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

  function testIssueByNonIssuerRevert() public {
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

  function testIssueAlreadyIssuedRevert() public {
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

contract DocumentStore_bulkIssue_Test is CommonTest {
  bytes32[] public docHashes;

  function setUp() public override {
    super.setUp();

    vm.startPrank(owner);
    documentStore.grantRole(documentStore.ISSUER_ROLE(), issuer);
    vm.stopPrank();

    docHashes = new bytes32[](2);
    docHashes[0] = "0x1234";
    docHashes[1] = "0x5678";
  }

  function testBulkIssueByIssuer() public {
    vm.expectEmit(true, false, false, true);
    emit IDocumentStore.DocumentIssued(docHashes[0]);
    vm.expectEmit(true, false, false, true);
    emit IDocumentStore.DocumentIssued(docHashes[1]);

    vm.prank(issuer);
    documentStore.bulkIssue(docHashes);

    assert(documentStore.isRootIssued(docHashes[0]));
    assert(documentStore.isRootIssued(docHashes[1]));
  }

  function testBulkIssueByRevokerRevert() public {
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        revoker,
        documentStore.ISSUER_ROLE()
      )
    );

    vm.prank(revoker);
    documentStore.bulkIssue(docHashes);
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
    documentStore.bulkIssue(docHashes);
  }

  function testBulkIssueWithDuplicatesRevert() public {
    docHashes[1] = docHashes[0];

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.DocumentExists.selector, bytes32(docHashes[1])));

    vm.prank(issuer);
    documentStore.bulkIssue(docHashes);
  }
}

abstract contract DocumentStoreWithFakeDocuments_Base is CommonTest {
  bytes32 public docRoot;
  bytes32[] public documents = new bytes32[](3);
  bytes32[][] public proofs = new bytes32[][](3);

  function setUp() public virtual override {
    super.setUp();

    docRoot = 0x5f0ed7e331c430ce34bcb45e2ddbff2b56a0f5971a226eee85f7ed6cc85e8e27;

    documents = [
      bytes32(0x795bb6abe4c5bb81e397821324d44bf7a94785587d0c88c621f57268c8aef4cb),
      bytes32(0x9bc394ef702b639adb913242a472e883f4834b4f38ed38f046bec8fcc1104fa3),
      bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
    ];

    proofs = [
      [
        bytes32(0x9bc394ef702b639adb913242a472e883f4834b4f38ed38f046bec8fcc1104fa3),
        bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
      ],
      [
        bytes32(0x795bb6abe4c5bb81e397821324d44bf7a94785587d0c88c621f57268c8aef4cb),
        bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
      ]
    ];
    proofs.push([bytes32(0x3763f4f892fb4c2ff4d76c4b9d391985568f8940f93f71283a84ff73277fb81e)]);
  }
}

contract DocumentStore_isIssued_Test is DocumentStoreWithFakeDocuments_Base {
  function setUp() public override {
    super.setUp();

    vm.prank(issuer);
    documentStore.issue(docRoot);
  }

  function testIsRootIssuedWithRoot() public {
    assertTrue(documentStore.isRootIssued(docRoot));
  }

  function testIsRootIssuedWithZeroRoot() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    documentStore.isRootIssued(0x0);
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

contract DocumentStore_revokeRoot_Test is DocumentStoreWithFakeDocuments_Base {
  function setUp() public override {
    super.setUp();

    vm.prank(issuer);
    documentStore.issue(docRoot);
  }

  function testRevokeRootByOwner() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, docRoot);

    vm.prank(owner);
    documentStore.revokeRoot(docRoot);

    assertTrue(documentStore.isRootRevoked(docRoot));
  }

  function testRevokeRootByRevoker() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, docRoot);

    vm.prank(revoker);
    documentStore.revokeRoot(docRoot);

    assertTrue(documentStore.isRootRevoked(docRoot));
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
    documentStore.revokeRoot(docRoot);
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
    documentStore.revokeRoot(docRoot);
  }

  function testRevokeRootWithZeroRoot() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    vm.prank(revoker);
    documentStore.revokeRoot(0x0);
  }

  function testRevokeRootAlreadyRevokedRevert() public {
    vm.startPrank(revoker);
    documentStore.revokeRoot(docRoot);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InactiveDocument.selector, docRoot, docRoot));

    documentStore.revokeRoot(docRoot);
    vm.stopPrank();
  }

  function testRevokeRootNonIssuedRootRevert() public {
    bytes32 nonIssuedRoot = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, nonIssuedRoot, nonIssuedRoot));

    vm.prank(revoker);
    documentStore.revokeRoot(nonIssuedRoot);
  }
}

contract DocumentStore_revoke_Test is DocumentStoreWithFakeDocuments_Base {
  function setUp() public override {
    super.setUp();

    vm.prank(issuer);
    documentStore.issue(docRoot);
  }

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

  function testRevokeNonIssuedDocumentRevert() public {
    bytes32 nonIssuedRoot = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, nonIssuedRoot, nonIssuedRoot));

    vm.prank(revoker);
    documentStore.revokeRoot(nonIssuedRoot);
  }
}

contract DocumentStore_bulkRevoke_Test is DocumentStoreWithFakeDocuments_Base {
  bytes32[] public docRoots = new bytes32[](3);

  function setUp() public override {
    super.setUp();

    docRoots[0] = docRoot;
    docRoots[1] = docRoot;
    docRoots[2] = docRoot;

    vm.prank(issuer);
    documentStore.issue(docRoot);
  }

  function testBulkRevokeByOwner() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, documents[0]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, documents[1]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, documents[2]);

    vm.prank(owner);
    documentStore.bulkRevoke(docRoots, documents, proofs);

    assertTrue(documentStore.isRevoked(docRoot, documents[0], proofs[0]));
    assertTrue(documentStore.isRevoked(docRoot, documents[1], proofs[1]));
    assertTrue(documentStore.isRevoked(docRoot, documents[2], proofs[2]));
  }

  function testBulkRevokeByRevoker() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, documents[0]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, documents[1]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoot, documents[2]);

    vm.prank(revoker);
    documentStore.bulkRevoke(docRoots, documents, proofs);

    assertTrue(documentStore.isRevoked(docRoot, documents[0], proofs[0]));
    assertTrue(documentStore.isRevoked(docRoot, documents[1], proofs[1]));
    assertTrue(documentStore.isRevoked(docRoot, documents[2], proofs[2]));
  }

  function testBulkRevokeByIssuerRevert() public {
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        issuer,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(issuer);
    documentStore.bulkRevoke(docRoots, documents, proofs);
  }

  function testBulkRevokeByNonRevokerRevert() public {
    address notRevoker = vm.addr(69);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        notRevoker,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(notRevoker);
    documentStore.bulkRevoke(docRoots, documents, proofs);
  }

  function testBulkRevokeWithDuplicatesRevert() public {
    docRoots[1] = docRoots[0];
    documents[1] = documents[0];
    proofs[1] = proofs[0];

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InactiveDocument.selector, docRoots[1], documents[1]));

    vm.prank(revoker);
    documentStore.bulkRevoke(docRoots, documents, proofs);
  }
}

contract DocumentStore_isRevoked_Test is DocumentStoreWithFakeDocuments_Base {
  function setUp() public override {
    super.setUp();

    vm.startPrank(owner);
    documentStore.issue(docRoot);
    documentStore.revoke(docRoot, documents[0], proofs[0]);
    vm.stopPrank();
  }

  function testIsRevokedWithRevokedDocument() public {
    assertTrue(documentStore.isRevoked(docRoot, documents[0], proofs[0]));
  }

  function testIsRevokedWithRevokedRoot() public {
    vm.prank(revoker);
    documentStore.revokeRoot(docRoot);

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

contract DocumentStore_isRootRevoked is DocumentStoreWithFakeDocuments_Base {
  function setUp() public override {
    super.setUp();

    vm.startPrank(owner);
    documentStore.issue(docRoot);
    documentStore.revokeRoot(docRoot);
    vm.stopPrank();
  }

  function testIsRootRevokedWithRevokedRoot() public {
    assertTrue(documentStore.isRootRevoked(docRoot));
  }

  function testIsRootRevokedWithNotRevokedRoot() public {
    bytes32 notRevokedRoot = "0x1234";

    vm.prank(issuer);
    documentStore.issue(notRevokedRoot);

    assertFalse(documentStore.isRootRevoked(notRevokedRoot));
  }

  function testIsRootRevokedWithZeroRootRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.ZeroDocument.selector));

    documentStore.isRootRevoked(0x0);
  }

  function testIsRootRevokedWithNotIssuedRootRevert() public {
    bytes32 notIssuedRoot = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, notIssuedRoot, notIssuedRoot));

    assertFalse(documentStore.isRootRevoked(notIssuedRoot));
  }
}

contract DocumentStore_isActive_Test is DocumentStoreWithFakeDocuments_Base {
  function setUp() public override {
    super.setUp();

    vm.startPrank(owner);
    documentStore.issue(docRoot);
    documentStore.revoke(docRoot, documents[0], proofs[0]);
    vm.stopPrank();
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

  function testIsActiveWithNotIssuedDocumentRevert() public {
    bytes32 notIssuedDoc = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IDocumentStore.InvalidDocument.selector, docRoot, notIssuedDoc));

    documentStore.isActive(docRoot, notIssuedDoc, proofs[0]);
  }
}
