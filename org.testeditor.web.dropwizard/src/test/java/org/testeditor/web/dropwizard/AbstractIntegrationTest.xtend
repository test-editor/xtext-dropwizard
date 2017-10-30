package org.testeditor.web.dropwizard

import de.xtendutils.junit.AssertionHelper
import io.dropwizard.testing.ResourceHelpers
import io.dropwizard.testing.junit.DropwizardAppRule
import javax.ws.rs.client.Invocation.Builder
import org.junit.Rule
import org.testeditor.web.dropwizard.auth.JWTAuthenticatorTest

import static io.dropwizard.testing.ConfigOverride.config

abstract class AbstractIntegrationTest {

    val configs = #[
        config('server.applicationConnectors[0].port', '0')
    ]

    @Rule
    public val dropwizardAppRule = new DropwizardAppRule(
        ExampleApplication,
        ResourceHelpers.resourceFilePath('test-config.yml'),
        configs
    )

    protected extension val AssertionHelper = AssertionHelper.instance
    protected val client = dropwizardAppRule.client
    var token = JWTAuthenticatorTest.createToken

    protected def Builder createRequest(String relativePath) {
        val uri = '''http://localhost:«dropwizardAppRule.localPort»/«relativePath»'''
        val builder = client.target(uri).request
        builder.header('Authorization', '''Bearer «token»''')
        return builder
    }

}
