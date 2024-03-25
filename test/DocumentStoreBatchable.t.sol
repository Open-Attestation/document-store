// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "../src/DocumentStore.sol";
import "../src/interfaces/IDocumentStore.sol";
import "../src/interfaces/IDocumentStoreBatchable.sol";
import "./CommonTest.t.sol";

contract DocumentStoreBatchable_revoke_Test is DocumentStoreBatchable_Initializer {
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
    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.InvalidDocument.selector, docRoot, documents[0]));

    vm.prank(revoker);
    documentStore.revoke(docRoot, documents[0], proofs[1]);
  }

  function testRevokeWithEmptyProofRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.InvalidDocument.selector, docRoot, documents[0]));

    vm.prank(revoker);
    documentStore.revoke(docRoot, documents[0], new bytes32[](0));
  }

  function testRevokeWithZeroDocument() public {
    vm.startPrank(revoker);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.ZeroDocument.selector));
    documentStore.revoke(0x0, documents[0], proofs[0]);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.ZeroDocument.selector));
    documentStore.revoke(docRoot, 0x0, proofs[0]);

    vm.stopPrank();
  }

  function testRevokeAlreadyRevokedRevert() public {
    vm.startPrank(revoker);

    documentStore.revoke(docRoot, documents[0], proofs[0]);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.InactiveDocument.selector, docRoot, documents[0]));

    documentStore.revoke(docRoot, documents[0], proofs[0]);

    vm.stopPrank();
  }

  function testRevokeAlreadyRevokedRootRevert() public {
    vm.startPrank(revoker);

    documentStore.revoke(docRoot);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.InactiveDocument.selector, docRoot, documents[0]));

    documentStore.revoke(docRoot, documents[0], proofs[0]);

    vm.stopPrank();
  }

  function testRevokeNotIssuedDocumentRevert() public {
    bytes32 nonIssuedRoot = "0x1234";

    vm.expectRevert(
      abi.encodeWithSelector(IDocumentStoreErrors.DocumentNotIssued.selector, nonIssuedRoot, nonIssuedRoot)
    );

    vm.prank(revoker);
    documentStore.revoke(nonIssuedRoot);
  }
}

contract DocumentStoreBatchable_multicall_revoke_Test is DocumentStoreBatchable_multicall_revoke_Initializer {
  function setUp() public override {
    super.setUp();

    bulkRevokeData = new bytes[](3);
    bulkRevokeData[0] = abi.encodeCall(IDocumentStoreBatchable.revoke, (docRoot(), documents()[0], proofs()[0]));
    bulkRevokeData[1] = abi.encodeCall(IDocumentStoreBatchable.revoke, (docRoot(), documents()[1], proofs()[1]));
    bulkRevokeData[2] = abi.encodeCall(IDocumentStoreBatchable.revoke, (docRoot(), documents()[2], proofs()[2]));
  }
}

contract DocumentStoreBatchable_isRevoked_Test is DocumentStoreBatchable_Initializer {
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
    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.InvalidDocument.selector, docRoot, documents[0]));

    documentStore.isRevoked(docRoot, documents[0], proofs[1]);
  }

  function testIsRevokedWithEmptyProofRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.InvalidDocument.selector, docRoot, documents[0]));

    documentStore.isRevoked(docRoot, documents[0], new bytes32[](0));
  }

  function testIsRevokedWithZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.ZeroDocument.selector));
    documentStore.isRevoked(docRoot, 0x0, proofs[0]);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.ZeroDocument.selector));
    documentStore.isRevoked(0x0, documents[0], proofs[0]);
  }

  function testIsRevokedWithNotIssuedDocumentRevert() public {
    bytes32 notIssuedDoc = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.InvalidDocument.selector, docRoot, notIssuedDoc));

    documentStore.isRevoked(docRoot, notIssuedDoc, proofs[0]);
  }
}

contract DocumentStoreBatchable_isActive_Test is DocumentStoreBatchable_Initializer {
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
    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.InvalidDocument.selector, docRoot, documents[0]));

    documentStore.isActive(docRoot, documents[0], proofs[1]);
  }

  function testIsActiveWithEmptyProofRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.InvalidDocument.selector, docRoot, documents[0]));

    documentStore.isActive(docRoot, documents[0], new bytes32[](0));
  }

  function testIsActiveWithZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.ZeroDocument.selector));
    documentStore.isActive(docRoot, 0x0, proofs[0]);

    vm.expectRevert(abi.encodeWithSelector(IDocumentStoreErrors.ZeroDocument.selector));
    documentStore.isActive(0x0, documents[0], proofs[0]);
  }

  function testIsActiveWithNotIssuedDocumentRevert(bytes32 notIssuedDoc) public {
    vm.assume(notIssuedDoc != docRoot && notIssuedDoc != bytes32(0));

    vm.expectRevert(
      abi.encodeWithSelector(IDocumentStoreErrors.DocumentNotIssued.selector, notIssuedDoc, notIssuedDoc)
    );

    documentStore.isActive(notIssuedDoc, notIssuedDoc, new bytes32[](0));
  }

  function testIsActiveWithNotIssuedRootRevert() public {
    bytes32 notIssuedRoot = 0xb841229d504c5c9bcb8132078db8c4a483825ad811078144c6f9aec84213d798;
    bytes32 notIssuedDoc = 0xd56c26db0fde817dcd82269d0f9a3f50ea256ee0c870e43c3ec2ebdd655e3f37;

    bytes32[] memory proofs = new bytes32[](1);
    proofs[0] = 0x9800b3feae3c44fe4263f6cbb2d8dd529c26c3a1c3ca7208a30cfa5efbc362e7;

    vm.expectRevert(
      abi.encodeWithSelector(IDocumentStoreErrors.DocumentNotIssued.selector, notIssuedRoot, notIssuedDoc)
    );

    documentStore.isActive(notIssuedRoot, notIssuedDoc, proofs);
  }
}
