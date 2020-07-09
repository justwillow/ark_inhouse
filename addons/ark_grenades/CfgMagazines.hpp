class CfgMagazines {
    class SatchelCharge_Remote_Mag;
    class SatchelCharge_Remote_Mag_Throwable: SatchelCharge_Remote_Mag {
        author = "ARK";
        ammo = "SatchelCharge_Remote_Ammo_Thrown";
        scope = 1;
        class Library {
            libTextDesc = "An explosive satchel that is throwable. 7 second fixed fuse";
        };
        descriptionUse = "";
        initSpeed = 15;
        weaponPoolAvailable = 0;
        useActionTitle = "";
        displayName = "Explosive Satchel (Throwable)";
        displayNameShort = "Satchel Charge";
        ace_explosives_Placeable = 0;
        useAction = 0;
        class ACE_Triggers {
            SupportedTriggers[] = {};
        };
    };
};