package org.testeditor.web.xtext.index.persistence

import com.google.common.annotations.VisibleForTesting
import com.jcraft.jsch.JSch
import com.jcraft.jsch.JSchException
import com.jcraft.jsch.Session
import java.io.File
import java.io.IOException
import java.util.List
import java.util.Set
import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.jgit.api.CloneCommand
import org.eclipse.jgit.api.CreateBranchCommand
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.api.GitCommand
import org.eclipse.jgit.api.TransportCommand
import org.eclipse.jgit.api.errors.JGitInternalException
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.errors.RepositoryNotFoundException
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.merge.MergeStrategy
import org.eclipse.jgit.transport.JschConfigSessionFactory
import org.eclipse.jgit.transport.OpenSshConfig.Host
import org.eclipse.jgit.transport.SshTransport
import org.eclipse.jgit.treewalk.AbstractTreeIterator
import org.eclipse.jgit.treewalk.CanonicalTreeParser
import org.eclipse.jgit.treewalk.EmptyTreeIterator
import org.eclipse.jgit.util.FS
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory

import static org.eclipse.jgit.lib.ConfigConstants.CONFIG_KEY_URL
import static org.eclipse.jgit.lib.ConfigConstants.CONFIG_REMOTE_SECTION
import static org.eclipse.jgit.lib.Constants.*

import static extension org.apache.commons.io.FileUtils.deleteDirectory

/**
 * provide some service around a git repo (read only)
 */
@Singleton
class GitService {
	/**
	 * Wrapper around static methods of class Git for testing / mocknig purposes.
	 */
	static class GitAccess {
		def Git open(File workingCopyDir) throws IOException {
			return Git.open(workingCopyDir)
		}
		def CloneCommand cloneRepository() {
			return Git.cloneRepository
		}
	}
	
	@Inject GitAccess gitAccess

	static val logger = LoggerFactory.getLogger(GitService)

	@Accessors(PROTECTED_GETTER)
	@VisibleForTesting
	Git git

	@Accessors(PUBLIC_GETTER)
	File projectFolder

	String privateKeyLocation
	String knownHostsLocation

	/**
	 * initialize this git service. either open the existing git and pull, or clone the remote repo
	 */
	def void init(String localRepoFileRoot, String remoteRepoUrl, String branchName, String privateKeyLocation, String knownHostsLocation) {
		logger.info("Initializing with localRepoFileRoot='{}', remoteRepoUrl='{}', branch='{}'.", localRepoFileRoot, remoteRepoUrl, branchName)
		this.privateKeyLocation = privateKeyLocation
		this.knownHostsLocation = knownHostsLocation
		projectFolder = verifyIsFolderOrNonExistent(localRepoFileRoot)
		if (isExistingGitRepository(projectFolder)) {
			try {
				openRepository(projectFolder, remoteRepoUrl, branchName)
				pull
			} catch (JGitInternalException | RepositoryNotFoundException ex) {
				logger.error('Failed to open existing working copy. Fallback: delete and clone a fresh working copy.', ex)
				projectFolder.deleteDirectory
				cloneRepository(projectFolder, remoteRepoUrl, branchName)
			}
		} else {
			cloneRepository(projectFolder, remoteRepoUrl, branchName)
		}
	}

	def void init(String localRepoFileRoot, String remoteRepoUrl) {
		init(localRepoFileRoot, remoteRepoUrl, 'master', null, null)
	}

	def void init(String localRepoFileRoot, String remoteRepoUrl, String branchName) {
		init(localRepoFileRoot, remoteRepoUrl, branchName, null, null)
	}

	def String getBranchName() {
		return git.repository.branch
	}
	
	def Set<String> getConflicts() {
		return git.status.call.conflicting
	}

	private def File verifyIsFolderOrNonExistent(String localRepoFileRoot) {
		val file = new File(localRepoFileRoot)
		val existsButIsNotAFolder = file.exists && !file.isDirectory
		if (existsButIsNotAFolder) {
			val message = '''Configured localRepoFileRoot=«localRepoFileRoot» is not a directory!'''
			throw new IllegalArgumentException(message)
		}
		return file
	}

	@VisibleForTesting
	protected def boolean isExistingGitRepository(File folder) {
		return folder.exists && new File(folder, DOT_GIT).exists
	}

	/**
	 * configure transport commands with ssh credentials (if configured for this dropwizard app)
	 */
	def <T, C extends GitCommand<T>> GitCommand<T> configureTransport(TransportCommand<C, T> command) {
		command.setSshSessionFactory
		return command
	}

	def void pull() {
		git.pull.setStrategy(MergeStrategy.THEIRS).configureTransport.call
	}

	def ObjectId getHeadTree() {
		return git.repository.resolve('HEAD^{tree}')
	}

	/**
	 * calculate diff between these two commits
	 */
	def List<DiffEntry> calculateDiff(String oldHeadCommit, String newHeadCommit) {
		return calculateDiff(ObjectId.fromString(oldHeadCommit), ObjectId.fromString(newHeadCommit))
	}

	/**
	 * Calculates diff of the provided commit against the empty tree.
	 *
	 * This basically lists all files under version control up to the specified
	 * commit, i.e. all diff entries being returned are going to be of change
	 * type 'ADD'. This is handy for change detection, to handle a situation
	 * in which all files need to be treated as new (e.g. after the working copy
	 * has just been cloned from a remote) in the same manner as any other diff
	 * against a specific revision.
	 */
	def List<DiffEntry> allFilesAsDiff(String newHeadCommit) {
		return calculateDiffAgainstEmptyTree(ObjectId.fromString(newHeadCommit))
	}

	private def List<DiffEntry> calculateDiff(ObjectId oldHead, ObjectId newHead) {
		logger.info("Calculating diff between old='{}' and new='{}'.", oldHead.getName, newHead.getName)
		val reader = git.repository.newObjectReader
		try {
			val oldTree = new CanonicalTreeParser => [reset(reader, oldHead)]
			val newTree = new CanonicalTreeParser => [reset(reader, newHead)]
			return calculateDiff(oldTree, newTree)
		} finally {
			reader.close
		}
	}

	private def List<DiffEntry> calculateDiffAgainstEmptyTree(ObjectId newHead) {
		logger.info("Calculating diff of '{}' against empty tree.", newHead.getName)
		val reader = git.repository.newObjectReader
		try {
			val oldTree = new EmptyTreeIterator
			val newTree = new CanonicalTreeParser => [reset(reader, newHead)]
			return calculateDiff(oldTree, newTree)
		} finally {
			reader.close
		}
	}

	private def List<DiffEntry> calculateDiff(AbstractTreeIterator oldTree, AbstractTreeIterator newTree) {
		val diff = git.diff.setOldTree(oldTree).setNewTree(newTree).call
		logger.info("Calculated diff='{}'.", diff)
		return diff
	}

	private def void cloneRepository(File projectFolder, String remoteRepoUrl, String branchName) {
		val cloneCommand = gitAccess.cloneRepository => [
			setURI(remoteRepoUrl)
			setSshSessionFactory
			setDirectory(projectFolder)
		]
		git = cloneCommand.call
		git.checkoutBranch(branchName)
	}

	private def void checkoutBranch(Git git, String branchName) {
		git.checkout => [
			if (!git.branchList.call.exists [
				val existingBranchName = name.replaceFirst('^refs/heads/', '')
				return existingBranchName == branchName
			]) {
 	       		setCreateBranch(true)
        		setUpstreamMode(CreateBranchCommand.SetupUpstreamMode.TRACK)
        	}
 			setName(branchName)
 			setStartPoint("origin/" + branchName)
 			call
 		]

	}

	@VisibleForTesting
	protected def void openRepository(File projectFolder, String remoteRepoUrl, String branchName) {
		git = gitAccess.open(projectFolder)
		git.checkout.setName(branchName).call
		verifyRemoteOriginMatches(remoteRepoUrl)
	}

	private def void verifyRemoteOriginMatches(String configuredRemoteRepoUrl) {
		val currentRemoteUrl = remoteUrl
		if (currentRemoteUrl != configuredRemoteRepoUrl) {
			val message = '''
				The currently existing Git repository remote URL does not match the configured one.
					repository location: «git.repository.directory»
					remote origin: «currentRemoteUrl»
					remote origin as per configuration: «configuredRemoteRepoUrl»
			'''
			throw new IllegalArgumentException(message)
		}
	}

	private def String getRemoteUrl() {
		val config = git.repository.config
		return config.getString(CONFIG_REMOTE_SECTION, DEFAULT_REMOTE_NAME, CONFIG_KEY_URL)
	}

	private def <T, C extends GitCommand<T>> void setSshSessionFactory(TransportCommand<C, ?> command) {

		val sshSessionFactory = new JschConfigSessionFactory {

			override protected void configure(Host host, Session session) {
				logger.info('''HashKnownHosts = «session.getConfig('HashKnownHosts')»''')
				logger.info('''StrictHostKeyChecking = «session.getConfig('StrictHostKeyChecking')»''')
			}

			// provide custom private key location (if not located at ~/.ssh/id_rsa)
			// provide custom known hosts file location (if not located at ~/.ssh/known_hosts)
			// see also http://www.codeaffine.com/2014/12/09/jgit-authentication/
			override protected JSch createDefaultJSch(FS fs) throws JSchException {
				val defaultJSch = super.createDefaultJSch(fs)
				if (!privateKeyLocation.isNullOrEmpty) {
					defaultJSch.addIdentity(privateKeyLocation)
					defaultJSch.identityNames.forEach[
						logger.info('''identity: «toString»''')
					]
					logger.info('''added private key from location: «privateKeyLocation»''')
				}
				if (!knownHostsLocation.isNullOrEmpty) {
					defaultJSch.knownHosts = knownHostsLocation
					defaultJSch.hostKeyRepository.hostKey.forEach [
						logger.info('''knownhost = «host», type = «type», key = «key», fingerprint = «getFingerPrint(defaultJSch)»''')
					]
				}
				return defaultJSch
			}

		}

		command.transportConfigCallback = [ transport |
			if (transport instanceof SshTransport) {
				transport.sshSessionFactory = sshSessionFactory
			}
		]

	}

}
