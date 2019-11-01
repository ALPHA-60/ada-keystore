-----------------------------------------------------------------------
--  keystore-passwords-gpg -- Password protected by GPG
--  Copyright (C) 2019 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------
with Ada.Streams;
with Ada.Strings.Unbounded;
with Ada.Finalization;
with Keystore;
with Keystore.Files;
package Keystore.Passwords.GPG is

   MAX_ENCRYPT_SIZE : constant := 1024;
   MAX_DECRYPT_SIZE : constant := 256;

   ENCRYPT_COMMAND : constant String := "gpg2 --encrypt --batch --yes -r $USER";
   DECRYPT_COMMAND : constant String := "gpg2 --decrypt --batch --yes --quiet";

   type Context_Type is limited new Ada.Finalization.Limited_Controlled
     and Slot_Provider with private;

   --  Create a secret to protect the keystore.
   procedure Create_Secret (Context : in out Context_Type);

   --  Save the GPG secret by encrypting it using the user's GPG key and storing
   --  the encrypted data in the keystore data header.
   procedure Save_Secret (Context : in out Context_Type;
                          User    : in String;
                          Wallet  : in out Keystore.Files.Wallet_File);

   --  Load the GPG secrets stored in the keystore header.
   procedure Load_Secrets (Context : in out Context_Type;
                           Wallet  : in out Keystore.Files.Wallet_File);

   --  Get the password through the Getter operation.
   overriding
   procedure Get_Password (From   : in Context_Type;
                           Getter : not null
                           access procedure (Password : in Secret_Key));

   --  Get the key slot number associated with the GPG password.
   overriding
   function Get_Key_Slot (From : in Context_Type) return Key_Slot;

   --  Returns true if the provider has a GPG password.
   overriding
   function Has_Password (From : in Context_Type) return Boolean;

   --  Move to the next GPG password.
   overriding
   procedure Next (From : in out Context_Type);

   --  Setup the command to be executed to encrypt the secret with GPG2.
   procedure Set_Encrypt_Command (Into    : in out Context_Type;
                                  Command : in String);

   --  Setup the command to be executed to decrypt the secret with GPG2.
   procedure Set_Decrypt_Command (Into    : in out Context_Type;
                                  Command : in String);

private

   type Secret_Provider;
   type Secret_Provider_Access is access all Secret_Provider;

   type Secret_Provider (Len : Key_Length) is limited record
      Next   : Secret_Provider_Access;
      Slot   : Key_Slot;
      Secret : Secret_Key (Length => Len);
   end record;

   type Context_Type is limited new Ada.Finalization.Limited_Controlled
     and Slot_Provider with record
      Current         : Secret_Provider_Access;
      First           : Secret_Provider_Access;
      Data            : Ada.Streams.Stream_Element_Array (1 .. MAX_DECRYPT_SIZE);
      Size            : Ada.Streams.Stream_Element_Offset;
      Encrypt_Command : Ada.Strings.Unbounded.Unbounded_String;
      Decrypt_Command : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   function Encrypt_GPG_Secret (Context : in Context_Type)
                                return Ada.Streams.Stream_Element_Array;

   procedure Decrypt_GPG_Secret (Context : in out Context_Type;
                                 Data    : in Ada.Streams.Stream_Element_Array);

   --  Get the command to encrypt the secret for the given GPG user/keyid.
   function Get_Encrypt_Command (Context : in Context_Type;
                                 User    : in String) return String;

   overriding
   procedure Initialize (Context : in out Context_Type);

   overriding
   procedure Finalize (Context : in out Context_Type);

end Keystore.Passwords.GPG;