// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import "./CommonTest.t.sol";

contract OwnableDocumentStore_init_Test is OwnableDocumentStoreCommonTest {
  function testDocumentStoreName() public {
    assertEq(documentStore.name(), storeName);
  }

  function testDocumentStoreSymbol() public {
    assertEq(documentStore.symbol(), storeSymbol);
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
    documentStore = new OwnableDocumentStore(storeName, storeSymbol, vm.addr(0));
  }
}

contract OwnableDocumentStore_issue_Test is OwnableDocumentStoreCommonTest {
  address public recipient;

  function setUp() public override {
    super.setUp();

    recipient = vm.addr(1234);
  }

  function testIssueAsIssuer(bytes32 document) public {
    vm.assume(document != bytes32(0));

    vm.prank(issuer);
    documentStore.issue(recipient, document);
  }

  function testIssueAsNonIssuerRevert(bytes32 document) public {
    vm.assume(document != bytes32(0));

    address nonIssuer = vm.addr(69);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        nonIssuer,
        documentStore.ISSUER_ROLE()
      )
    );

    vm.prank(nonIssuer);
    documentStore.issue(recipient, document);
  }

  function testIssueAsRevokerRevert(bytes32 document) public {
    vm.assume(document != bytes32(0));

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        revoker,
        documentStore.ISSUER_ROLE()
      )
    );

    vm.prank(revoker);
    documentStore.issue(recipient, document);
  }

  function testIssueToRecipient(bytes32 document) public {
    vm.assume(document != bytes32(0));

    vm.prank(issuer);
    documentStore.issue(recipient, document);

    address docOwner = documentStore.ownerOf(uint256(document));

    assertTrue(docOwner == recipient, "Document owner is not the recipient");
  }

  function testIssueToZeroRecipientRevert(bytes32 document) public {
    vm.assume(document != bytes32(0));

    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));

    vm.prank(issuer);
    documentStore.issue(address(0), document);
  }

  function testIssueToZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IOwnableDocumentStoreErrors.ZeroDocument.selector));

    vm.prank(issuer);
    documentStore.issue(recipient, bytes32(0));
  }

  function testIssueAlreadyIssuedDocumentToSameRecipientRevert(bytes32 document) public {
    vm.assume(document != bytes32(0));
    vm.prank(issuer);
    documentStore.issue(recipient, document);

    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidSender.selector, address(0)));

    vm.prank(issuer);
    documentStore.issue(recipient, document);
  }

  function testIssueAlreadyIssuedDocumentToDifferentRecipientRevert(bytes32 document) public {
    vm.assume(document != bytes32(0));
    vm.prank(issuer);
    documentStore.issue(recipient, document);

    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidSender.selector, address(0)));

    vm.prank(issuer);
    documentStore.issue(vm.addr(69), document);
  }

  function testIssueRevokedDocumentToSameRecipientRevert(bytes32 document) public {
    vm.assume(document != bytes32(0));
    vm.startPrank(owner);
    documentStore.issue(recipient, document);
    documentStore.revoke(document);
    vm.stopPrank();

    vm.expectRevert(abi.encodeWithSelector(IOwnableDocumentStoreErrors.DocumentIsRevoked.selector, document));

    vm.prank(issuer);
    documentStore.issue(recipient, document);
  }

  function testIssueRevokedDocumentToDifferentRecipientRevert(bytes32 document) public {
    vm.assume(document != bytes32(0));
    vm.startPrank(owner);
    documentStore.issue(recipient, document);
    documentStore.revoke(document);
    vm.stopPrank();

    vm.expectRevert(abi.encodeWithSelector(IOwnableDocumentStoreErrors.DocumentIsRevoked.selector, document));

    vm.prank(issuer);
    documentStore.issue(vm.addr(69), document);
  }
}

contract OwnableDocumentStore_revoke_Test is OwnableDocumentStore_Initializer {
  bytes32 public targetDocument;

  function setUp() public override {
    super.setUp();

    targetDocument = documents[0];
  }

  function testRevokeAsRevokerSuccess() public {
    vm.prank(revoker);
    documentStore.revoke(targetDocument);

    assertTrue(documentStore.isRevoked(targetDocument), "Document is should be revoked");
    assertEq(documentStore.balanceOf(recipients[0]), 0);
  }

  function testRevokeAsIssuerRevert() public {
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        issuer,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(issuer);
    documentStore.revoke(targetDocument);
  }

  function testRevokeAsNonRevokerRevert() public {
    address nonRevoker = vm.addr(69);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        nonRevoker,
        documentStore.REVOKER_ROLE()
      )
    );

    vm.prank(nonRevoker);
    documentStore.revoke(targetDocument);
  }

  function testRevokeZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 0x0));

    vm.prank(revoker);
    documentStore.revoke(bytes32(0));
  }

  function testRevokeNotIssuedDocumentRevert() public {
    bytes32 notIssuedDoc = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, notIssuedDoc));

    vm.prank(revoker);
    documentStore.revoke(notIssuedDoc);
  }

  function testRevokeAlreadyRevokedDocumentRevert() public {
    vm.prank(revoker);
    documentStore.revoke(targetDocument);

    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, targetDocument));

    vm.prank(revoker);
    documentStore.revoke(targetDocument);
  }

  function testRevokeDocumentOwnerIsZeroRevert() public {
    vm.prank(revoker);
    documentStore.revoke(targetDocument);

    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, targetDocument));

    documentStore.ownerOf(uint256(targetDocument));
  }
}

contract OwnableDocumentStore_isIssued_Test is OwnableDocumentStore_Initializer {
  function testIsIssued() public {
    assertTrue(documentStore.isIssued(documents[0]), "Document should be issued");
  }

  function testIsIssuedNotIssuedDocument() public {
    bytes32 notIssuedDoc = "0x1234";

    assertFalse(documentStore.isIssued(notIssuedDoc), "Document should not be issued");
  }

  function testIsIssuedRevokedDocument() public {
    vm.prank(revoker);
    documentStore.revoke(documents[0]);

    assertTrue(documentStore.isIssued(documents[0]), "Document should be issued");
  }

  function testIsIssuedZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IOwnableDocumentStoreErrors.ZeroDocument.selector));

    documentStore.isIssued(bytes32(0));
  }
}

contract OwnableDocumentStore_isRevoked_Test is OwnableDocumentStore_Initializer {
  function setUp() public override {
    super.setUp();

    vm.prank(revoker);
    documentStore.revoke(documents[0]);
  }

  function testIsRevoked() public {
    assertTrue(documentStore.isRevoked(documents[0]), "Document should be revoked");
  }

  function testIsRevokedNotRevokedDocument() public {
    assertFalse(documentStore.isRevoked(documents[1]), "Document should not be revoked");
  }

  function testIsRevokedNotIssuedDocumentRevert() public {
    bytes32 notIssuedDoc = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, notIssuedDoc));

    documentStore.isRevoked(notIssuedDoc);
  }

  function testIsRevokedZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IOwnableDocumentStoreErrors.ZeroDocument.selector));

    documentStore.isRevoked(bytes32(0));
  }
}

contract OwnableDocumentStore_isActive_Test is OwnableDocumentStore_Initializer {
  function testIsActive() public {
    assertTrue(documentStore.isActive(documents[0]), "Document should be active");
  }

  function testIsActiveRevertedDocument() public {
    vm.prank(revoker);
    documentStore.revoke(documents[0]);

    assertFalse(documentStore.isActive(documents[0]), "Document should not be active");
  }

  function testIsActiveNotIssuedDocumentRevert() public {
    bytes32 notIssuedDoc = "0x1234";

    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, notIssuedDoc));

    documentStore.isActive(notIssuedDoc);
  }

  function testIsActiveZeroDocumentRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IOwnableDocumentStoreErrors.ZeroDocument.selector));

    documentStore.isActive(bytes32(0));
  }
}

contract OwnableDocumentStore_transfer_Test is OwnableDocumentStore_Initializer {
  function testTransferFromToNewRecipient() public {
    vm.prank(recipients[0]);
    documentStore.transferFrom(recipients[0], recipients[1], uint256(documents[0]));

    address docOwner = documentStore.ownerOf(uint256(documents[0]));
    uint256 balanceOfRecipient0 = documentStore.balanceOf(recipients[0]);
    uint256 balanceOfRecipient1 = documentStore.balanceOf(recipients[1]);

    assertTrue(docOwner == recipients[1], "Document owner is not the recipient");
    assertEq(balanceOfRecipient0, 0);
    assertEq(balanceOfRecipient1, 2);
  }

  function testTransferFromToZeroRevert() public {
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));

    vm.prank(recipients[0]);
    documentStore.transferFrom(recipients[0], address(0), uint256(documents[0]));
  }
}

contract OwnableDocumentStore_supportsInterface_Test is OwnableDocumentStoreCommonTest {
  function testSupportsInterface() public {
    assertTrue(documentStore.supportsInterface(type(IOwnableDocumentStore).interfaceId));
    assertTrue(documentStore.supportsInterface(type(IDocumentStore).interfaceId));
    assertTrue(documentStore.supportsInterface(type(IERC721Metadata).interfaceId));
    assertTrue(documentStore.supportsInterface(type(IAccessControl).interfaceId));
  }
}
