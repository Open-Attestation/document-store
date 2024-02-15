// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/Test.sol";

import "../src/DocumentStore.sol";
import "./fixtures/DocumentStoreFixture.sol";
import "../src/OwnableDocumentStore.sol";

abstract contract CommonTest is Test {
  address public owner = vm.addr(1);
  address public issuer = vm.addr(2);
  address public revoker = vm.addr(3);

  function setUp() public virtual {}
}

abstract contract DocumentStoreCommonTest is CommonTest {
  DocumentStore public documentStore;

  string public storeName = "DocumentStore Test";

  function setUp() public virtual override {
    super.setUp();

    vm.startPrank(owner);

    documentStore = new DocumentStore(storeName, owner);
    documentStore.grantRole(documentStore.ISSUER_ROLE(), issuer);
    documentStore.grantRole(documentStore.REVOKER_ROLE(), revoker);

    vm.stopPrank();
  }
}

abstract contract DocumentStore_Initializer is DocumentStoreCommonTest {
  bytes32[] public documents;

  DocumentStoreFixture private _fixture;

  function setUp() public virtual override {
    super.setUp();

    _fixture = new DocumentStoreFixture();

    documents = _fixture.documents();

    bytes[] memory issueData = new bytes[](3);
    issueData[0] = abi.encodeCall(documentStore.issue, (documents[0]));
    issueData[1] = abi.encodeCall(documentStore.issue, (documents[1]));
    issueData[2] = abi.encodeCall(documentStore.issue, (documents[2]));

    vm.prank(issuer);
    documentStore.multicall(issueData);
  }
}

abstract contract DocumentStoreBatchable_Initializer is DocumentStoreCommonTest {
  bytes32 public docRoot;
  bytes32[] public documents = new bytes32[](3);
  bytes32[][] public proofs = new bytes32[][](3);

  DocumentStoreBatchableFixture private _fixture;

  function setUp() public virtual override {
    super.setUp();

    _fixture = new DocumentStoreBatchableFixture();

    docRoot = _fixture.docRoot();

    documents = _fixture.documents();

    proofs = _fixture.proofs();

    vm.prank(issuer);
    documentStore.issue(docRoot);
  }
}

abstract contract DocumentStore_multicall_revoke_Base is DocumentStoreCommonTest {
  bytes[] public bulkRevokeData;

  function docRoots() public view virtual returns (bytes32[] memory);

  function documents() public view virtual returns (bytes32[] memory);

  function proofs() public view virtual returns (bytes32[][] memory);

  function testMulticallRevokeByOwner() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots()[0], documents()[0]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots()[1], documents()[1]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots()[2], documents()[2]);

    vm.prank(owner);
    documentStore.multicall(bulkRevokeData);

    assertTrue(documentStore.isRevoked(docRoots()[0], documents()[0], proofs()[0]));
    assertTrue(documentStore.isRevoked(docRoots()[1], documents()[1], proofs()[1]));
    assertTrue(documentStore.isRevoked(docRoots()[2], documents()[2], proofs()[2]));
  }

  function testMulticallRevokeByRevoker() public {
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots()[0], documents()[0]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots()[1], documents()[1]);
    vm.expectEmit(true, true, false, true);
    emit IDocumentStore.DocumentRevoked(docRoots()[2], documents()[2]);

    vm.prank(revoker);
    documentStore.multicall(bulkRevokeData);

    assertTrue(documentStore.isRevoked(docRoots()[0], documents()[0], proofs()[0]));
    assertTrue(documentStore.isRevoked(docRoots()[1], documents()[1], proofs()[1]));
    assertTrue(documentStore.isRevoked(docRoots()[2], documents()[2], proofs()[2]));
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
    // Make document1 same as document0
    bulkRevokeData[1] = abi.encodeCall(IDocumentStoreBatchable.revoke, (docRoots()[0], documents()[0], proofs()[0]));

    // It should revert that document0 is already inactive
    vm.expectRevert(
      abi.encodeWithSelector(IDocumentStoreErrors.InactiveDocument.selector, docRoots()[0], documents()[0])
    );

    vm.prank(revoker);
    documentStore.multicall(bulkRevokeData);
  }
}

abstract contract DocumentStoreBatchable_multicall_revoke_Initializer is DocumentStore_multicall_revoke_Base {
  DocumentStoreBatchableFixture private _fixture;

  function docRoot() public view virtual returns (bytes32) {
    return _fixture.docRoot();
  }

  function docRoots() public view virtual override returns (bytes32[] memory) {
    bytes32[] memory roots = new bytes32[](3);
    roots[0] = _fixture.docRoot();
    roots[1] = _fixture.docRoot();
    roots[2] = _fixture.docRoot();
    return roots;
  }

  function documents() public view virtual override returns (bytes32[] memory) {
    return _fixture.documents();
  }

  function proofs() public view virtual override returns (bytes32[][] memory) {
    return _fixture.proofs();
  }

  function setUp() public virtual override {
    super.setUp();

    _fixture = new DocumentStoreBatchableFixture();

    vm.startPrank(issuer);
    documentStore.issue(docRoot());
    vm.stopPrank();
  }
}

abstract contract DocumentStore_multicall_revoke_Initializer is DocumentStore_multicall_revoke_Base {
  DocumentStoreFixture private _fixture;

  function docRoots() public view virtual override returns (bytes32[] memory) {
    // Set up the document fixtures to be independent documents
    bytes32[] memory roots = new bytes32[](3);
    roots[0] = _fixture.documents()[0];
    roots[1] = _fixture.documents()[1];
    roots[2] = _fixture.documents()[2];
    return roots;
  }

  function documents() public view virtual override returns (bytes32[] memory) {
    return _fixture.documents();
  }

  function proofs() public view virtual override returns (bytes32[][] memory) {
    // We want the documents to be independent, thus no need proofs
    bytes32[][] memory _proofs = new bytes32[][](3);
    _proofs[0] = new bytes32[](0);
    _proofs[1] = new bytes32[](0);
    _proofs[2] = new bytes32[](0);
    return _proofs;
  }

  function setUp() public virtual override {
    super.setUp();

    _fixture = new DocumentStoreFixture();

    bytes[] memory issueData = new bytes[](3);
    issueData[0] = abi.encodeCall(documentStore.issue, (documents()[0]));
    issueData[1] = abi.encodeCall(documentStore.issue, (documents()[1]));
    issueData[2] = abi.encodeCall(documentStore.issue, (documents()[2]));

    vm.prank(issuer);
    documentStore.multicall(issueData);
  }
}

abstract contract OwnableDocumentStoreCommonTest is CommonTest {
  OwnableDocumentStore public documentStore;

  string public storeName = "OwnableDocumentStore Test";
  string public storeSymbol = "XYZ";

  function setUp() public virtual override {
    super.setUp();

    vm.startPrank(owner);
    documentStore = new OwnableDocumentStore(storeName, storeSymbol, owner);
    documentStore.grantRole(documentStore.ISSUER_ROLE(), issuer);
    documentStore.grantRole(documentStore.REVOKER_ROLE(), revoker);
    vm.stopPrank();
  }
}

abstract contract OwnableDocumentStore_Initializer is OwnableDocumentStoreCommonTest {
  bytes32[] public documents;
  address[] public recipients;

  function setUp() public virtual override {
    super.setUp();

    documents = new bytes32[](2);
    documents[0] = "0x1111";
    documents[1] = "0x2222";

    recipients = new address[](2);
    recipients[0] = vm.addr(4);
    recipients[1] = vm.addr(5);

    vm.startPrank(issuer);
    documentStore.issue(recipients[0], documents[0], false);
    documentStore.issue(recipients[1], documents[1], true);
    vm.stopPrank();
  }
}
