/* Copyright (c) 1999-2004 Ng Pheng Siong. All rights reserved. */
/* $Id$ */

%{
#include <openssl/evp.h>

#if OPENSSL_VERSION_NUMBER >= 0x0090800fL
#include <openssl/aes.h>
#endif

/* 
// 2004-10-10, ngps: 
// CTR mode is not included in the default OpenSSL build.
// To use the AES CTR ciphers, link with your own copy of OpenSSL.
*/
#ifdef HAVE_AES_CTR
extern EVP_CIPHER const *EVP_aes_128_ctr(void);
extern EVP_CIPHER const *EVP_aes_192_ctr(void);
extern EVP_CIPHER const *EVP_aes_256_ctr(void);
#endif
%}

%apply Pointer NONNULL { AES_KEY * };

%constant int AES_BLOCK_SIZE = AES_BLOCK_SIZE;

%inline %{
AES_KEY *aes_new(void) {
    AES_KEY *key;
    
    if (!(key = (AES_KEY *)PyMem_Malloc(sizeof(AES_KEY)))) {
        PyErr_SetString(PyExc_MemoryError,
                        "Insufficient memory for AES key.");
        return NULL;
    }
    return key;
}   

void AES_free(AES_KEY *key) {
    PyMem_Free((void *)key);
}

/* 
// op == 0: decrypt
// otherwise: encrypt (Python code will supply the value 1.)
*/
PyObject *AES_set_key(AES_KEY *key, PyObject *value, int bits, int op) { 
    const void *vbuf; 
    Py_ssize_t vlen;

    if (PyObject_AsReadBuffer(value, &vbuf, &vlen) == -1)
        return NULL;

    if (op == 0) 
        AES_set_encrypt_key(vbuf, bits, key);
    else
        AES_set_decrypt_key(vbuf, bits, key);
    Py_RETURN_NONE;
}

/* 
// op == 0: decrypt
// otherwise: encrypt (Python code will supply the value 1.)
*/
PyObject *AES_crypt(const AES_KEY *key, PyObject *in, int outlen, int op) {
    const void *buf;
    Py_ssize_t len;
    unsigned char *out;
    PyObject *res;

    if (PyObject_AsReadBuffer(in, &buf, &len) == -1)
        return NULL;

    if (!(out=(unsigned char *)PyMem_Malloc(outlen))) {
        PyErr_SetString(PyExc_MemoryError, "AES_crypt");
        return NULL;
    }
    if (op == 0)
        AES_encrypt((const unsigned char *)in, out, key);
    else
        AES_decrypt((const unsigned char *)in, out, key);
#if PY_MAJOR_VERSION >= 3
    return PyBytes_FromStringAndSize((char*)out, outlen);
#else
    return PyString_FromStringAndSize((char*)out, outlen);
#endif // PY_MAJOR_VERSION >= 3
    PyMem_Free(out);
    return res;
}

int AES_type_check(AES_KEY *key) {
    return 1;
}
%}
