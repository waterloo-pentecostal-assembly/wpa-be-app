/// Minimum password length enforced at sign-up/sign-in.
const kMinPasswordLength = 8;

const kEmailRegex =
    r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";

/// Stricter password rule (letters + digits). Currently not enforced.
const kPasswordRegex = r"""^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$""";
