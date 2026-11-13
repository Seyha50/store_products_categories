<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
       Schema::create('categories', function (Blueprint $t) {
    $t->id('category_id');
            $t->string('category_name', 50);
            $t->string('description', 255)->nullable();
            $t->string('image', 255);
            $t->timestamp('created_at')->useCurrent();
            $t->timestamp('updated_at')->nullable();
});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
