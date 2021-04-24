pragma solidity 0.7.3;

interface IFxERC1155 {
    function fxManager() external returns(address);
    function initialize(address fxManager_, address connectedToken_, string memory uri_) external;
    function connectedToken() external returns(address);
    function mint(address user, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address user, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function burn(address user, uint256 id, uint256 amount) external;
    function burnBatch(address user, uint256[] memory ids, uint256[] memory amounts) external;
}