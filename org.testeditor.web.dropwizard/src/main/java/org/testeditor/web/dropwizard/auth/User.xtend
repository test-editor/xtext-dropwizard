package org.testeditor.web.dropwizard.auth

import java.security.Principal
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.EqualsHashCode
import org.eclipse.xtend.lib.annotations.ToString

@Accessors(PUBLIC_GETTER)
@ToString
@EqualsHashCode
class User implements Principal {

    String id
    String name
    String email

    private new() { // default constructor for Jackson
    }

    new(String id, String name, String email) {
        this.id = id
        this.name = name
        this.email = email
    }

}
