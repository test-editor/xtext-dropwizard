package org.testeditor.web.xtext.index.persistence

import java.io.File
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.api.errors.TransportException
import org.eclipse.jgit.lib.Constants
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.transport.URIish
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExpectedException
import org.junit.rules.TemporaryFolder

class GitServiceInitTest extends AbstractGitTest {
	
	@Rule public TemporaryFolder keyfiles = new TemporaryFolder
	@Rule public ExpectedException expectedException = ExpectedException.none
	
	@Test
	def void cloneTriesToUsePrivateKeyIfConfigured() {
		// given
		val invalidPrivateKey = write(keyfiles.root, 'invalid-private-key-file', 'invalid-private-key-content')
		expectedException.expect(TransportException)
		expectedException.expectMessage('invalid privatekey')
		
		// when
		gitService.init(localRepoRoot.path, 'git@git.example.com:test-editor/test-editor-examples.git', invalidPrivateKey.absolutePath, null)
		
		// then (expected exception is thrown)
	}
	
	@Test
	def void cloneUsesPrivateKeyIfConfiguredButFailsOnHostThen() {
		// given
		val dummyButValidPrivateKey = write(keyfiles.root, 'dummy-private-key-file',
			'''
				-----BEGIN RSA PRIVATE KEY BLOCK-----
				
				lQHYBFo7o+MBBADJg6nDraGCWwCCs4+J+VZP94htAXOgzY3LekOumSH55ywNPluM
				gc5FPljiCS+UNEl1yYk+oFshClXhVSevtur/mXgUYck9V8n81fOlJBKPowJ/KiC5
				KdHRJX7SdUEvK0UymNsIEIhAyqGCT/9OcpIZSJy0mJoaY50da4rxaod9KQARAQAB
				AAP9FJmqGX/phTWfsrzVIqoOTHR7SjFzdu/XMVhEDQLzOeSLrfrpnvkyHgVb+WzY
				+VHzDzXVcEUyVl6uctpNXqWDa66dgbP/Cwwtjs8JT1ws919/9HuXtnC1mCvyTwHv
				zi4AA9I9dARvWc/urMzW1ywW+Xhf96qnX0sPvivw1YxwmQUCANluybZP0Wu+srTc
				4GFJtyZZwfPZZUWmApeo9CQ+VqQcVxs4OmvlO3BKsh+hVjOJdpTdfV7tzbpcp5DD
				TmeduqsCAO1CDFDi1LaW5lnKEHNlOMKv5d94BRJXW+nd9UjXVPm1U8tVZ1tfXZIo
				x4VZWIPIPdmvs1X8Xa/FkLqbJ0LsZ3sCAM+4mfcCuuRwUiiqyGPTh1LQ2aWFtWSU
				0Svw9y7RqSJhgCsNcJxpgQDUl7cQcQ0LgaGTMlvyzZ825xDHUi07dhek0bQjdGVz
				dGVkaXRvciA8dGVzdGVkaXRvckBleGFtcGxlLmNvbT6IuAQTAQIAIgUCWjuj4wIb
				AwYLCQgHAwIGFQgCCQoLBBYCAwECHgECF4AACgkQWwCvCdlYmPf8XAP7BXlqNYgn
				D73QU6Rixk0txWF2gi4R+VuHPsxuM0LhzHNh1MKsrCAyIdAGUdQUzQNI1d3Z7UdG
				3uFUKRzdoHigc4yRjq2imN5DZm+xONtkt1y2tDeu9e0XkaOlsIazS4HzbKeJvd+n
				AChJdHV8UAxjjm43lm2AOm6Wm5e98eFD5o2dAdgEWjuj4wEEALU7tZQj3+36+Z4I
				jkoQjgTTz5Q/hnY7i8kpr1iCQkd4mR5mYOsTtDzaSa4R/pBMArrPB4p3x4JiDIL5
				QaA+LtaSsQTXDSd8NuESWSxgDGg2fr+J9U2HT9TmeZR2XMUoARr2QBr2uQuJJrwF
				Qa9cDfl9F+yqvIlCdcpNVQoIryh7ABEBAAEAA/9PnsPPKVOfwbsYarnYYB2EkWmI
				v7/bAZ4P6nhWciOcMqdSa7f4jteIRH5KMy2bR0mLuJifhK/p4BmPEOJ7+9WnQcGr
				YqnuJ6lFn3fud/aANjGepsE3+Re4qJSfIWQtUuDdpQyjvyuIShkVck2G3YbMJX0O
				lE2iNhVjkCtVcHgQQQIA0O5tPKdXxzku2wjOt/6zXJKaASyySzaEeK88J0+nq4ow
				4R69rFseNd5aCSapSQz27I63unt4UsXr1zkGbYKPPwIA3g/doOT8byVE4Z97UagP
				ExhrBp2DLAapjZwu/9ppCRs418uS0XNp005cnq8tzyp25YbSxAtgJJymJb3JdVrT
				xQIAnBOxCGac6AH/Ypt6vtJeHp81OxN6ADPq4hOLU1e0jRHz/wAXjXTj+mQ611NE
				BqqozKixwRyM8VtLM6xcDoszNZyxiJ8EGAECAAkFAlo7o+MCGwwACgkQWwCvCdlY
				mPf7wAP/WUXIjMWRUj+fc9BwXNwuMkNMvCrgv0vlknB8nRqAClE+kchTIALU3Ejb
				oeH/IcZ9lEnLC80eTnh8AuY+iAnCAN54udblx4x1xz7NwXZq6e8KVoHC7KtoM2ho
				EOEXryHZ6kNpO+cMSyey6xPA6zZR2yNY0fgDHdh8mVzgghR6c/o=
				=KbQq
				-----END RSA PRIVATE KEY BLOCK-----
			''')
		expectedException.expect(TransportException)
		expectedException.expectMessage('unknown host')
		
		// when
		gitService.init(localRepoRoot.path, 'git@git.example.com:test-editor/test-editor-examples.git', dummyButValidPrivateKey.absolutePath, null)
		
		// then (expected exception is thrown)
	}
	


	@Test
	def void clonesRemoteRepositoryWhenUninitialized() {
		// given
		val remoteHead = createExampleFileOnRemote()

		// when
		gitService.init(localRepoRoot.path, remoteRepoRoot.path)

		// then
		val lastLocalCommit = Git.init.setDirectory(localRepoRoot).call.lastCommit
		lastLocalCommit.assertEquals(remoteHead)
		gitService.headTree.name().assertEquals(lastLocalCommit.tree.name())
	}

	@Test
	def void isExistingGitRepositoryReturnsTrueForExistingRepository() {
		// given
		Git.init.setDirectory(localRepoRoot).call

		// when + then
		gitService.isExistingGitRepository(localRepoRoot).assertTrue
	}

	@Test
	def void isExistingGitRepositoryReturnsFalseForEmptyFolder() {
		// when + then
		gitService.isExistingGitRepository(localRepoRoot).assertFalse
	}

	@Test
	def void canReusesExistingGitRepository() {
		// given
		val remoteHead = createExampleFileOnRemote()
		Git.cloneRepository.setDirectory(localRepoRoot).setURI(remoteRepoRoot.path).call

		// when
		gitService.init(localRepoRoot.path, remoteRepoRoot.path)

		// then
		gitService.git.lastCommit.assertEquals(remoteHead)
	}

	@Test
	def void failsOnExistingGitRepositoryWithWrongRemote() {
		// given
		val localGit = Git.init.setDirectory(localRepoRoot).call
		localGit.remoteAdd => [
			name = Constants.DEFAULT_REMOTE_NAME
			uri = new URIish('http://example.com')
			call
		]

		// when + then
		expectedException.expect(IllegalArgumentException)
		expectedException.expectMessage('The currently existing Git repository remote URL does not match the configured one.')
		gitService.init(localRepoRoot.path, remoteRepoRoot.path)
	}

	@Test
	def void throwsExceptionOnInvalidLocalRepoFileRoot() {
		// given
		write(localRepoRoot, 'demo.txt', 'test')
		val invalidLocalRepoFileRoot = new File(localRepoRoot, 'demo.txt').path

		// when + then
		expectedException.expect(IllegalArgumentException)
		expectedException.expectMessage('''Configured localRepoFileRoot=«invalidLocalRepoFileRoot» is not a directory!''')
		gitService.init(invalidLocalRepoFileRoot, remoteRepoRoot.path)
	}

	private def RevCommit createExampleFileOnRemote() {
		write(remoteRepoRoot, 'example.txt', 'dummy content')
		addAndCommit(remoteGit, 'example.txt', 'first commit')
		return remoteGit.lastCommit
	}

}
