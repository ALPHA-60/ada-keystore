-----------------------------------------------------------------------
--  keystore-passwords-files -- File based password provider
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
with Interfaces.C.Strings;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Util.Files;
with Util.Systems.Types;
with Util.Systems.Os;
package body Keystore.Passwords.Files is

   use Ada.Strings.Unbounded;
   subtype Key_Length is Util.Encoders.Key_Length;

   --  GNAT 2019 complains about unused use type but gcc 7.4 fails if it not defined (st_mode).
   pragma Warnings (Off);
   use type Interfaces.C.unsigned;
   use type Interfaces.C.unsigned_short;
   pragma Warnings (On);

   type Provider (Len : Key_Length) is limited
   new Keystore.Passwords.Provider with record
      Password : Secret_Key (Length => Len);
   end record;

   --  Get the password through the Getter operation.
   overriding
   procedure Get_Password (From   : in Provider;
                           Getter : not null access procedure (Password : in Secret_Key));

   --  ------------------------------
   --  Create a password provider that reads the file to build the password.
   --  ------------------------------
   function Create (Path : in String) return Provider_Access is
      Content : Unbounded_String;
      P       : Interfaces.C.Strings.chars_ptr;
      Stat    : aliased Util.Systems.Types.Stat_Type;
      Res     : Integer;
   begin
      --  Verify that the file is readable only by the current user.
      P := Interfaces.C.Strings.New_String (Path);
      Res := Util.Systems.Os.Sys_Stat (Path => P,
                                       Stat => Stat'Access);
      Interfaces.C.Strings.Free (P);
      if Res /= 0 then
         raise Keystore.Bad_Password with "Password file does not exist";
      end if;
      if (Stat.st_mode and 8#0077#) /= 0 then
         raise Keystore.Bad_Password with "Password file is not safe";
      end if;

      --  Verify that the parent directory is readable only by the current user.
      P := Interfaces.C.Strings.New_String (Ada.Directories.Containing_Directory (Path));
      Res := Util.Systems.Os.Sys_Stat (Path => P,
                                       Stat => Stat'Access);
      Interfaces.C.Strings.Free (P);
      if Res /= 0 then
         raise Keystore.Bad_Password
         with "Directory that contains password file cannot be checked";
      end if;
      if (Stat.st_mode and 8#0077#) /= 0 then
         raise Keystore.Bad_Password
         with "Directory that contains password file is not safe";
      end if;

      Util.Files.Read_File (Path => Path,
                            Into => Content);

      return new Provider '(Len      => Key_Length (Length (Content)),
                            Password => Create (To_String (Content)));
   end Create;

   --  ------------------------------
   --  Get the password through the Getter operation.
   --  ------------------------------
   overriding
   procedure Get_Password (From   : in Provider;
                           Getter : not null access procedure (Password : in Secret_Key)) is
   begin
      Getter (From.Password);
   end Get_Password;

end Keystore.Passwords.Files;
