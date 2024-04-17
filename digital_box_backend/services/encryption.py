from cryptography.fernet import Fernet
import base64

# Generate a master key for the double ratchet
master_key = Fernet.generate_key()

# Dictionary to store the sender and receiver keys
sender_keys = {}
receiver_keys = {}

def generate_key():
    return Fernet.generate_key()

def encrypt_data(data, key):
    fernet = Fernet(key)
    encrypted_data = fernet.encrypt(data.encode())
    return encrypted_data

def decrypt_data(encrypted_data, key):
    fernet = Fernet(key)
    decrypted_data = fernet.decrypt(encrypted_data).decode()
    return decrypted_data

def double_ratchet_encrypt(sender, receiver, message):
    if sender not in sender_keys:
        sender_keys[sender] = generate_key()
    if receiver not in receiver_keys:
        receiver_keys[receiver] = generate_key()

    sender_key = sender_keys[sender]
    receiver_key = receiver_keys[receiver]

    # Perform the double ratchet encryption
    encrypted_message = encrypt_data(message, sender_key)
    encrypted_message = encrypt_data(encrypted_message, receiver_key)

    # Update the sender and receiver keys for the next message
    sender_keys[sender] = generate_key()
    receiver_keys[receiver] = generate_key()

    return base64.b64encode(encrypted_message).decode()

def double_ratchet_decrypt(sender, receiver, encrypted_message):
    if sender not in sender_keys or receiver not in receiver_keys:
        return None

    sender_key = sender_keys[sender]
    receiver_key = receiver_keys[receiver]

    # Perform the double ratchet decryption
    encrypted_message = base64.b64decode(encrypted_message.encode())
    decrypted_message = decrypt_data(encrypted_message, receiver_key)
    decrypted_message = decrypt_data(decrypted_message, sender_key)

    return decrypted_message
