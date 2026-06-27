<?php

declare(strict_types=1);

it('renders the welcome page with the container id', function (): void {
    $response = $this->get(route('home'));

    $response->assertOk()
        ->assertInertia(fn ($page) => $page
            ->component('welcome')
            ->where('containerId', gethostname() ?: 'unknown'));
});
