<script lang="ts">
	import githubJson from '$lib/data/github.json';
</script>

<div class="grid-container">
	{#each Object.keys(githubJson) as githubUrl, index}
		{@const ownerRepo = githubUrl.replace('https://github.com/', '')}
		<div class="grid-row">
			<div class="index">{index + 1}</div>
			<div class="checkbox">
				<input
					type="checkbox"
					onchange={(e) => {
						if (e.currentTarget.checked) {
							navigator.clipboard.writeText(githubUrl).catch((err) => {
								console.error('Failed to copy to clipboard:', err);
							});
						}
					}}
				/>
			</div>
			<div class="repo">
				<a href={githubUrl} target="_blank">{ownerRepo}</a>
			</div>
		</div>
	{/each}
</div>

<style>
	.grid-container {
		display: grid;
		gap: 0;
	}

	.grid-row {
		display: grid;
		grid-template-columns: 4rem 3rem 1fr;
		align-items: center;
		border-bottom: 1px solid var(--pico-muted-border-color);
		padding: 0.5rem 0;
	}

	.grid-row:last-child {
		border-bottom: none;
	}

	.index {
		text-align: right;
		padding-right: 1rem;
		color: var(--pico-muted-color);
	}

	.checkbox {
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.repo {
		padding-left: 0.5rem;
	}
</style>
