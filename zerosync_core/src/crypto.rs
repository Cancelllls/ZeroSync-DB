use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, AeadCore, Nonce
};
use sha2::{Digest, Sha256};

pub struct ZeroCrypto {
    cipher: Aes256Gcm,
}

impl ZeroCrypto {
    pub fn new(passphrase: &str) -> Self {
        let mut hasher = Sha256::new();
        hasher.update(passphrase.as_bytes());
        let key_bytes = hasher.finalize();
        let cipher = Aes256Gcm::new_from_slice(&key_bytes).expect("Valid 256-bit key length");
        Self { cipher }
    }

    pub fn encrypt(&self, plain_text: &str) -> Result<String, String> {
        let nonce = Aes256Gcm::generate_nonce(&mut OsRng);
        let ciphertext = self
            .cipher
            .encrypt(&nonce, plain_text.as_bytes())
            .map_err(|e| format!("Encryption error: {:?}", e))?;

        let combined = format!("{}:{}", hex::encode(nonce), hex::encode(ciphertext));
        Ok(combined)
    }

    pub fn decrypt(&self, combined_ciphertext: &str) -> Result<String, String> {
        let parts: Vec<&str> = combined_ciphertext.split(':').collect();
        if parts.len() != 2 {
            return Err("Invalid ZeroSync ciphertext format".into());
        }

        let nonce_bytes = hex::decode(parts[0]).map_err(|e| format!("Hex decode error: {:?}", e))?;
        let ciphertext_bytes = hex::decode(parts[1]).map_err(|e| format!("Hex decode error: {:?}", e))?;

        let nonce = Nonce::from_slice(&nonce_bytes);
        let decrypted_bytes = self
            .cipher
            .decrypt(nonce, ciphertext_bytes.as_ref())
            .map_err(|e| format!("Decryption error: {:?}", e))?;

        String::from_utf8(decrypted_bytes).map_err(|e| format!("UTF8 parse error: {:?}", e))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rust_aes_gcm_encrypt_decrypt() {
        let crypto = ZeroCrypto::new("secret-passphrase-key");
        let original = "Hello ZeroSync-Core Rust!";
        let encrypted = crypto.encrypt(original).unwrap();
        assert_ne!(original, encrypted);

        let decrypted = crypto.decrypt(&encrypted).unwrap();
        assert_eq!(original, decrypted);
    }
}
