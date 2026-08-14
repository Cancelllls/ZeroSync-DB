pub mod crypto;
pub mod hlc;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use crypto::ZeroCrypto;
use hlc::Hlc;

/// C-FFI export: Encrypt payload string with passphrase key.
#[no_mangle]
pub extern "C" fn zerosync_encrypt(
    passphrase_ptr: *const c_char,
    plain_text_ptr: *const c_char,
) -> *mut c_char {
    if passphrase_ptr.is_null() || plain_text_ptr.is_null() {
        return std::ptr::null_mut();
    }

    unsafe {
        let passphrase = match CStr::from_ptr(passphrase_ptr).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };
        let plain_text = match CStr::from_ptr(plain_text_ptr).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };

        let crypto = ZeroCrypto::new(passphrase);
        match crypto.encrypt(plain_text) {
            Ok(encrypted) => CString::new(encrypted).unwrap().into_raw(),
            Err(_) => std::ptr::null_mut(),
        }
    }
}

/// C-FFI export: Decrypt ciphertext string with passphrase key.
#[no_mangle]
pub extern "C" fn zerosync_decrypt(
    passphrase_ptr: *const c_char,
    ciphertext_ptr: *const c_char,
) -> *mut c_char {
    if passphrase_ptr.is_null() || ciphertext_ptr.is_null() {
        return std::ptr::null_mut();
    }

    unsafe {
        let passphrase = match CStr::from_ptr(passphrase_ptr).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };
        let ciphertext = match CStr::from_ptr(ciphertext_ptr).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };

        let crypto = ZeroCrypto::new(passphrase);
        match crypto.decrypt(ciphertext) {
            Ok(decrypted) => CString::new(decrypted).unwrap().into_raw(),
            Err(_) => std::ptr::null_mut(),
        }
    }
}

/// C-FFI export: Generate current HLC timestamp for a node ID.
#[no_mangle]
pub extern "C" fn zerosync_hlc_now(node_id_ptr: *const c_char) -> *mut c_char {
    if node_id_ptr.is_null() {
        return std::ptr::null_mut();
    }

    unsafe {
        let node_id = match CStr::from_ptr(node_id_ptr).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };

        let hlc = Hlc::now(node_id.to_string());
        CString::new(hlc.to_string_fmt()).unwrap().into_raw()
    }
}

/// Free memory allocated for C-FFI returned strings.
#[no_mangle]
pub extern "C" fn zerosync_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}
