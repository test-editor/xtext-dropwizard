package org.testeditor.web.dropwizard.auth

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target

@Retention(RetentionPolicy.RUNTIME)
@Target(#[ElementType.TYPE, ElementType.METHOD])
annotation ApiTokenAuth {
}