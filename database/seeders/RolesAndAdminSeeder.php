<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class RolesAndAdminSeeder extends Seeder
{
    /**
     * Seed the baseline roles and a default admin account.
     */
    public function run(): void
    {
        // Roles that drive Freemium gating + access control.
        foreach (['admin', 'premium', 'free', 'content-creator'] as $role) {
            Role::firstOrCreate(['name' => $role, 'guard_name' => 'web']);
        }

        $admin = User::firstOrCreate(
            ['email' => 'admin@b5hunt.test'],
            [
                'name' => 'b5hunt Admin',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
            ],
        );
        $admin->syncRoles(['admin']);
    }
}
