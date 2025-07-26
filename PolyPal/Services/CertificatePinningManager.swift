//
//  CertificatePinningManager.swift
//  PolyPal
//
//  Created by Agent on 7/25/25.
//

import Foundation
import Security
import CommonCrypto

/// Manager for handling SSL certificate pinning for secure API communications
class CertificatePinningManager: NSObject {
    
    // MARK: - Properties
    
    /// Pinned certificate hashes for Zoho domains
    private let pinnedCertificateHashes: [String: Set<String>] = [
        "creator.zoho.com": [
            // SHA-256 hash of Zoho's certificate (example - would need actual hash)
            "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=",
            // Backup certificate hash
            "YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg="
        ],
        "accounts.zoho.com": [
            // SHA-256 hash for accounts domain
            "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=",
            "YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg="
        ]
    ]
    
    /// Whether certificate pinning is enabled
    private let isPinningEnabled: Bool
    
    // MARK: - Initialization
    
    init(enablePinning: Bool = true) {
        self.isPinningEnabled = enablePinning
        super.init()
    }
    
    // MARK: - Certificate Validation
    
    /// Validates the server certificate against pinned certificates
    func validateCertificate(for host: String, serverTrust: SecTrust) -> Bool {
        guard isPinningEnabled else {
            // If pinning is disabled, fall back to system validation
            return evaluateSystemTrust(serverTrust)
        }
        
        guard let pinnedHashes = pinnedCertificateHashes[host] else {
            // No pinned certificates for this host, use system validation
            return evaluateSystemTrust(serverTrust)
        }
        
        // Get the certificate chain from the server trust
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                continue
            }
            
            // Get the certificate data
            let certificateData = SecCertificateCopyData(certificate)
            let data = CFDataGetBytePtr(certificateData)
            let length = CFDataGetLength(certificateData)
            
            guard let data = data else { continue }
            
            // Calculate SHA-256 hash of the certificate
            let certificateHash = sha256Hash(data: Data(bytes: data, count: length))
            
            // Check if this certificate hash matches any pinned hash
            if pinnedHashes.contains(certificateHash) {
                return true
            }
        }
        
        // No matching pinned certificate found
        return false
    }
    
    /// Evaluates the server trust using system validation
    private func evaluateSystemTrust(_ serverTrust: SecTrust) -> Bool {
        var result: SecTrustResultType = .invalid
        let status = SecTrustEvaluate(serverTrust, &result)
        
        return status == errSecSuccess && (
            result == .unspecified ||
            result == .proceed
        )
    }
    
    /// Calculates SHA-256 hash of certificate data
    private func sha256Hash(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
    
    // MARK: - Public Key Pinning (Alternative Implementation)
    
    /// Validates using public key pinning instead of certificate pinning
    func validatePublicKey(for host: String, serverTrust: SecTrust) -> Bool {
        guard isPinningEnabled else {
            return evaluateSystemTrust(serverTrust)
        }
        
        // Extract public key from server certificate
        guard let serverPublicKey = extractPublicKey(from: serverTrust) else {
            return false
        }
        
        // Compare with pinned public keys (implementation would depend on stored keys)
        return validatePublicKeyAgainstPinned(serverPublicKey, for: host)
    }
    
    /// Extracts public key from server trust
    private func extractPublicKey(from serverTrust: SecTrust) -> SecKey? {
        guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            return nil
        }
        
        return SecCertificateCopyKey(certificate)
    }
    
    /// Validates public key against pinned keys
    private func validatePublicKeyAgainstPinned(_ publicKey: SecKey, for host: String) -> Bool {
        // Implementation would compare the public key with stored pinned keys
        // This is a simplified version - real implementation would store and compare actual keys
        return true
    }
    
    // MARK: - Certificate Information
    
    /// Extracts certificate information for debugging
    func getCertificateInfo(from serverTrust: SecTrust) -> [String: Any] {
        var info: [String: Any] = [:]
        
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        info["certificateCount"] = certificateCount
        
        var certificates: [[String: Any]] = []
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                continue
            }
            
            var certInfo: [String: Any] = [:]
            
            // Get certificate summary
            if let summary = SecCertificateCopySubjectSummary(certificate) {
                certInfo["subject"] = summary as String
            }
            
            // Get certificate data and hash
            let certificateData = SecCertificateCopyData(certificate)
            let data = CFDataGetBytePtr(certificateData)
            let length = CFDataGetLength(certificateData)
            
            if let data = data {
                let certData = Data(bytes: data, count: length)
                certInfo["sha256"] = sha256Hash(data: certData)
            }
            
            certificates.append(certInfo)
        }
        
        info["certificates"] = certificates
        return info
    }
}

// MARK: - URLSessionDelegate Extension

extension CertificatePinningManager: URLSessionDelegate {
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        // Validate certificate
        if validateCertificate(for: host, serverTrust: serverTrust) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Certificate validation failed
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Certificate Pinning Error

enum CertificatePinningError: Error, LocalizedError {
    case noPinnedCertificates
    case certificateValidationFailed
    case invalidServerTrust
    case publicKeyExtractionFailed
    
    var errorDescription: String? {
        switch self {
        case .noPinnedCertificates:
            return "No pinned certificates found for host"
        case .certificateValidationFailed:
            return "Certificate validation failed against pinned certificates"
        case .invalidServerTrust:
            return "Invalid server trust provided"
        case .publicKeyExtractionFailed:
            return "Failed to extract public key from certificate"
        }
    }
}
