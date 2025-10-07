<script lang="ts">
	import youtubeJson from '$lib/data/youtube.json';
	import { onMount } from 'svelte';
	import { SvelteSet } from 'svelte/reactivity';

	let checkedVideos = new SvelteSet<string>();

	onMount(() => {
		const stored = localStorage.getItem('checked-youtube');
		if (stored) {
			try {
				const parsed = JSON.parse(stored);
				parsed.forEach((id: string) => checkedVideos.add(id));
			} catch (err) {
				console.error('Failed to parse checked videos from localStorage:', err);
			}
		}
	});

	function handleCheckboxChange(youtubeId: string, checked: boolean) {
		if (checked) {
			checkedVideos.add(youtubeId);
			const videoUrl = `https://www.youtube.com/watch?v=${youtubeId}`;
			navigator.clipboard.writeText(videoUrl).catch((err) => {
				console.error('Failed to copy to clipboard:', err);
			});
			window.open(videoUrl, 'YOUTUBE_VIDEO');
		} else {
			checkedVideos.delete(youtubeId);
		}
		localStorage.setItem('checked-youtube', JSON.stringify(Array.from(checkedVideos)));
	}
</script>

<div class="grid-container">
	{#each youtubeJson as video, index}
		<div class="grid-row">
			<div class="index">{index + 1}</div>
			<div class="checkbox">
				<input
					type="checkbox"
					checked={checkedVideos.has(video.id)}
					onchange={(e) => handleCheckboxChange(video.id, e.currentTarget.checked)}
				/>
			</div>
			<div class="repo">
				<a href={`https://www.youtube.com/watch?v=${video.id}`} target="_blank">{video.id}</a>
			</div>
			<div
				class="description"
				onclick={() => {
					navigator.clipboard.writeText(video.description).catch((err) => {
						console.error('Failed to copy description to clipboard:', err);
					});
				}}
			>
				{video.description}
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
		grid-template-columns: 4rem 3rem 10rem 1fr;
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

	.description {
		padding-left: 1rem;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		cursor: pointer;
	}
</style>
