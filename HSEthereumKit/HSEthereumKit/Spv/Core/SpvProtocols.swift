import Foundation
import HSCryptoKit

protocol ISpvStorage: IStorage {
    var lastBlockHeader: BlockHeader? { get }
    func save(blockHeaders: [BlockHeader])
}

protocol IRandomHelper: class {
    func randomKey() -> ECKey
    func randomBytes(length: Int) -> Data
    func randomBytes(length: Range<Int>) -> Data
}

protocol IFactory: class {
    func authMessage(signature: Data, publicKeyPoint: ECPoint, nonce: Data) -> AuthMessage
    func authAckMessage(data: Data) throws -> AuthAckMessage
    func keccakDigest() -> KeccakDigest
    func frameCodec(secrets: Secrets) -> FrameCodec
    func encryptionHandshake(myKey: ECKey, publicKey: Data) -> EncryptionHandshake
}

protocol IFrameCodecHelper {
    func updateMac(mac: KeccakDigest, macKey: Data, data: Data) -> Data
    func toThreeBytes(int: Int) -> Data
    func fromThreeBytes(data: Data) -> Int
}

protocol IAESCipher {
    func process(_ data: Data) -> Data
}

protocol IECIESCryptoUtils {
    func ecdhAgree(myKey: ECKey, remotePublicKeyPoint: ECPoint) -> Data
    func ecdhAgree(myPrivateKey: Data, remotePublicKeyPoint: Data) -> Data
    func concatKDF(_ data: Data) -> Data
    func sha256(_ data: Data) -> Data
    func aesEncrypt(_ data: Data, withKey: Data, keySize: Int, iv: Data) -> Data
    func hmacSha256(_ data: Data, key: Data, iv: Data, macData: Data) -> Data
}

protocol ICryptoUtils: class {
    func ecdhAgree(myKey: ECKey, remotePublicKeyPoint: ECPoint) -> Data
    func ellipticSign(_ messageToSign: Data, key: ECKey) throws -> Data
    func eciesDecrypt(privateKey: Data, message: ECIESEncryptedMessage) throws -> Data
    func eciesEncrypt(remotePublicKey: ECPoint, message: Data) -> ECIESEncryptedMessage
    func sha3(_ data: Data) -> Data
    func aesEncrypt(_ data: Data, withKey: Data, keySize: Int) -> Data
}

public protocol IEthereumKitDelegate: class {
    func onUpdate(transactions: [EthereumTransaction])
    func onUpdateBalance()
    func onUpdateLastBlockHeight()
    func onUpdateSyncState()
}


protocol ILESPeerDelegate: class {
    func didConnect()
    func didReceive(blockHeaders: [BlockHeader])
    func didReceive(proofMessage: ProofsMessage)
}

protocol IDevP2PPeerDelegate: class {
    func didConnect()
    func didDisconnect(error: Error?)
    func didReceive(message: IMessage)
}

protocol IConnectionDelegate: class {
    func didConnect()
    func didDisconnect(error: Error?)
    func didReceive(frame: Frame)
}

protocol ILESPeer: class {
    var delegate: ILESPeerDelegate? { get set }
    func connect()
    func disconnect(error: Error?)
    func requestBlockHeaders(fromBlockHash blockHash: Data)
    func requestProofs(forAddress address: Data, inBlockWithHash blockHash: Data)
}

protocol IConnection: class {
    var delegate: IConnectionDelegate? { get set }

    func connect()
    func disconnect(error: Error?)
    func send(frame: Frame)
}

protocol IFrameConnection: class {
    var delegate: IFrameConnectionDelegate? { get set }

    func connect()
    func disconnect(error: Error?)
    func send(packetType: Int, payload: Data)
}

protocol IFrameConnectionDelegate: class {
    func didConnect()
    func didDisconnect(error: Error?)
    func didReceive(packetType: Int, payload: Data)
}

protocol IDevP2PConnection: class {
    var delegate: IDevP2PConnectionDelegate? { get set }

    var myCapabilities: [Capability] { get }
    func register(nodeCapabilities: [Capability]) throws

    func connect()
    func disconnect(error: Error?)
    func send(message: IMessage)
}

protocol IDevP2PConnectionDelegate: class {
    func didConnect()
    func didDisconnect(error: Error?)
    func didReceive(message: IMessage)
}

protocol INetwork {
    var id: Int { get }
    var genesisBlockHash: Data { get }
    var checkpointBlock: BlockHeader { get }
    var coinType: UInt32 { get }
    var privateKeyPrefix: UInt32 { get }
    var publicKeyPrefix: UInt32 { get }
}

protocol IPeerGroupDelegate: class {
    func onUpdate(state: AccountState)
}

protocol IPeerGroup {
    var delegate: IPeerGroupDelegate? { get set }
    func start()
}

protocol IDevP2PPeer {
    func connect()
    func disconnect(error: Error?)
    func send(message: IMessage)
}

protocol IMessageFactory {
    func helloMessage(key: ECKey, capabilities: [Capability]) -> HelloMessage
    func pongMessage() -> PongMessage
    func getBlockHeadersMessage(blockHash: Data) -> GetBlockHeadersMessage
    func getProofsMessage(address: Data, blockHash: Data) -> GetProofsMessage
    func statusMessage(network: INetwork, blockHeader: BlockHeader) -> StatusMessage
}

protocol IMessage {
    init(data: Data) throws
    func encoded() -> Data
    func toString() -> String
}

protocol ILESPeerValidator {
    func validate(message: StatusMessage, network: INetwork, blockHeader: BlockHeader) throws
}
